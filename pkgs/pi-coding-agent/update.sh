#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl nix python3

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
VENDORED_LOCKFILE="$SCRIPT_DIR/package-lock.json"

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

url="https://github.com/earendil-works/pi/archive/refs/tags/v${latest_version}.tar.gz"
echo "Fetching source hash..."
hash_base64=$(nix-prefetch-url --unpack --type sha256 "$url" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E 's|( *hash = ").*(";)|\1'"${src_hash}"'\2|' "$DEFAULT_NIX_FILE"

echo "Vendoring fixed package-lock.json..."
python3 - <<'PY' "$latest_version" "$VENDORED_LOCKFILE"
import json, sys, urllib.parse, urllib.request
from pathlib import Path

version = sys.argv[1]
out = Path(sys.argv[2])
with urllib.request.urlopen(f"https://raw.githubusercontent.com/earendil-works/pi/v{version}/package-lock.json") as r:
    lock = json.load(r)
cache = {}
for path, pkg in lock["packages"].items():
    if not ((path.startswith("node_modules/") or "/node_modules/" in path) and "version" in pkg and "resolved" not in pkg and "link" not in pkg):
        continue
    name = pkg.get("name") or path.rsplit("node_modules/", 1)[1]
    key = (name, pkg["version"])
    if key not in cache:
        url = "https://registry.npmjs.org/" + urllib.parse.quote(name, safe="") + "/" + urllib.parse.quote(pkg["version"], safe="")
        with urllib.request.urlopen(url) as rr:
            meta = json.load(rr)
        dist = meta["dist"]
        cache[key] = {
            "resolved": dist["tarball"],
            "integrity": dist["integrity"],
        }
    pkg["resolved"] = cache[key]["resolved"]
    pkg["integrity"] = cache[key]["integrity"]

# Normalize URL-type dependency version specifiers in workspace package entries.
# importNpmLock preserves non-semver specifiers as-is, causing npm to try fetching
# the URL directly in offline mode. Replace with the resolved semver version.
url_deps_fixed = 0
for path, pkg in lock["packages"].items():
    for dep_name, dep_ver in list(pkg.get("dependencies", {}).items()):
        if dep_ver.startswith("http") or dep_ver.startswith("git"):
            nm_entry = lock["packages"].get("node_modules/" + dep_name, {})
            if nm_entry.get("version"):
                pkg["dependencies"][dep_name] = nm_entry["version"]
                url_deps_fixed += 1

out.write_text(json.dumps(lock, separators=(",", ":")))
print(f"Wrote {out} with {len(cache)} patched package versions, {url_deps_fixed} URL deps normalized")
PY

echo "Successfully updated pi-coding-agent to version $latest_version"
