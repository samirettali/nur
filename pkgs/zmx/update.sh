#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
NUR_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)

latest_version=$(curl --silent --fail \
  "https://api.github.com/repos/neurosnap/zmx/tags" \
  | jq -r '.[0].name' | sed 's/^v//')

current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "zmx is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating zmx from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

hash_base64=$(nix-prefetch-url --unpack --type sha256 \
  "https://github.com/neurosnap/zmx/archive/refs/tags/v${latest_version}.tar.gz" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E "s|( *hash = \").*(\";)|\1${src_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Successfully updated zmx to version $latest_version"
echo "NOTE: You may also need to update build.zig.zon.nix if ghostty or uucode dependency changed."
