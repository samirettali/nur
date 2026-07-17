#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix python3

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
VENDORED_LOCKFILE="$SCRIPT_DIR/package-lock.json"
NUR_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)

latest_version=$(curl --silent --fail \
  "https://api.github.com/repos/Leechael/pi-provider-kimi-code/releases/latest" \
  | jq -r .tag_name | sed 's/^v//')
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "pi-provider-kimi-code is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating pi-provider-kimi-code from $current_version to $latest_version"

sed -i -E 's/^( *version = ").*(";)/\1'"$latest_version"'\2/' "$DEFAULT_NIX_FILE"

url="https://github.com/Leechael/pi-provider-kimi-code/archive/refs/tags/v${latest_version}.tar.gz"
hash_base64=$(nix-prefetch-url --unpack --type sha256 "$url" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E 's|( *hash = ").*(";)|\1'"${src_hash}"'\2|' "$DEFAULT_NIX_FILE"

python3 - "$latest_version" "$VENDORED_LOCKFILE" <<'PY'
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

version = sys.argv[1]
out = Path(sys.argv[2])
with urllib.request.urlopen(
    f"https://raw.githubusercontent.com/Leechael/pi-provider-kimi-code/v{version}/package-lock.json"
) as response:
    lock = json.load(response)

lock["version"] = version
if "" in lock.get("packages", {}):
    lock["packages"][""]["version"] = version

cache = {}
for path, package in lock["packages"].items():
    if not (
        (path.startswith("node_modules/") or "/node_modules/" in path)
        and "version" in package
        and "link" not in package
        and ("resolved" not in package or "integrity" not in package)
    ):
        continue

    name = package.get("name") or path.rsplit("node_modules/", 1)[1]
    key = (name, package["version"])
    if key not in cache:
        if name.startswith("@"):
            scope, pkg = name.split("/", 1)
            encoded_name = f"{urllib.parse.quote(scope, safe='')}/{urllib.parse.quote(pkg, safe='')}"
        else:
            encoded_name = urllib.parse.quote(name, safe="")
        encoded_version = urllib.parse.quote(package["version"], safe="")
        with urllib.request.urlopen(
            f"https://registry.npmjs.org/{encoded_name}/{encoded_version}"
        ) as response:
            metadata = json.load(response)
        cache[key] = metadata["dist"]

    package["resolved"] = cache[key]["tarball"]
    package["integrity"] = cache[key]["integrity"]

out.write_text(json.dumps(lock, separators=(",", ":")) + "\n")
print(f"Wrote {out} with {len(cache)} patched package versions")
PY

nix build --no-link --impure --expr \
  "let repo = import ${NUR_ROOT} {}; in repo.pi-provider-kimi-code"

echo "Successfully updated pi-provider-kimi-code to version $latest_version"
