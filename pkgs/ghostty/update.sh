#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

today=$(date +%Y-%m-%d)
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$today" == "$current_version" ]]; then
  echo "ghostty is already up-to-date at version $today"
  exit 0
fi

echo "Updating ghostty from $current_version to $today"

sed -i -E "s/^( *version = \").*(\";)/\1$today\2/" "$DEFAULT_NIX_FILE"

hash_base64=$(nix-prefetch-url --type sha256 \
  "https://github.com/ghostty-org/ghostty/releases/download/tip/ghostty-macos-universal.zip" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E "s|( *hash = \").*(\";)|\1${src_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Successfully updated ghostty to version $today"
