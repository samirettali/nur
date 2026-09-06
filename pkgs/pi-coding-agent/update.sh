#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl nix prefetch-npm-deps python3

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
NUR_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)

echo "Fetching release information for earendil-works/pi..."
releases_json=$(curl --silent --fail "https://api.github.com/repos/earendil-works/pi/releases?per_page=100")
latest_version=$(python3 -c '
import json, re, sys

releases = json.load(sys.stdin)
semver_re = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")
candidates = []
for release in releases:
    if release.get("draft") or release.get("prerelease"):
        continue
    tag = release.get("tag_name") or ""
    match = semver_re.match(tag)
    if match:
        candidates.append((tuple(map(int, match.groups())), tag.removeprefix("v")))

if not candidates:
    raise SystemExit("No stable semver releases found")

print(max(candidates)[1])
' <<<"$releases_json")
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if python3 - "$current_version" "$latest_version" <<'PY'
import re, sys

def parse(version):
    match = re.fullmatch(r"v?(\d+)\.(\d+)\.(\d+)", version)
    if not match:
        raise SystemExit(f"Unsupported version format: {version}")
    return tuple(map(int, match.groups()))

sys.exit(0 if parse(sys.argv[2]) <= parse(sys.argv[1]) else 1)
PY
then
  echo "pi-coding-agent is already up-to-date at version $current_version; newest stable semver release is $latest_version"
  exit 0
fi

echo "Updating pi-coding-agent from $current_version to $latest_version"

sed -i -E 's/^( *version = ").*(";)/\1'"$latest_version"'\2/' "$DEFAULT_NIX_FILE"

to_sri() {
  nix hash convert --hash-algo sha256 --to sri "$1"
}

url="https://github.com/earendil-works/pi/archive/refs/tags/v${latest_version}.tar.gz"
echo "Fetching source hash..."
src_hash=$(to_sri "$(nix-prefetch-url --unpack --type sha256 "$url" 2>/dev/null)")
sed -i -E '/src = fetchFromGitHub/,/};/s|^( *hash = ").*(";)|\1'"${src_hash}"'\2|' "$DEFAULT_NIX_FILE"

npm_url="https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${latest_version}.tgz"
echo "Fetching pi-ai model data hash..."
model_hash=$(to_sri "$(nix-prefetch-url --unpack --type sha256 "$npm_url" 2>/dev/null)")
sed -i -E '/modelData = fetchzip/,/};/s|^( *hash = ").*(";)|\1'"${model_hash}"'\2|' "$DEFAULT_NIX_FILE"

echo "Prefetching npm dependencies..."
lockfile=$(mktemp)
trap 'rm -f "$lockfile"' EXIT
curl --silent --fail --location \
  "https://raw.githubusercontent.com/earendil-works/pi/v${latest_version}/package-lock.json" \
  --output "$lockfile"
npm_deps_hash=$(prefetch-npm-deps "$lockfile" 2>/dev/null | tail -n1)
sed -i -E 's|^( *npmDepsHash = ").*(";)|\1'"${npm_deps_hash}"'\2|' "$DEFAULT_NIX_FILE"

nix build --no-link --impure --expr \
  "let repo = import ${NUR_ROOT} {}; in repo.pi-coding-agent"

echo "Successfully updated pi-coding-agent to version $latest_version"
