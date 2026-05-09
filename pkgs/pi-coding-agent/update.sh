#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix python3

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
VENDORED_LOCKFILE="$SCRIPT_DIR/package-lock.json"

echo "Fetching latest release information for earendil-works/pi..."
latest_version=$(curl --silent --fail "https://api.github.com/repos/earendil-works/pi/releases/latest" | jq -r .tag_name | sed 's/^v//')
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "pi-coding-agent is already up-to-date at version $latest_version"
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
out.write_text(json.dumps(lock, separators=(",", ":")))
print(f"Wrote {out} with {len(cache)} patched package versions")
PY

echo "Successfully updated pi-coding-agent to version $latest_version"
