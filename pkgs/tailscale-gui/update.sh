#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

latest_version=$(curl --silent --fail \
  "https://pkgs.tailscale.com/stable/?mode=json" \
  | jq -r .MacZipsVersion)

current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "tailscale-gui is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating tailscale-gui from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

hash_base64=$(nix-prefetch-url --type sha256 \
  "https://pkgs.tailscale.com/stable/Tailscale-${latest_version}-macos.pkg" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E "s|( *hash = \").*(\";)|\1${src_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Successfully updated tailscale-gui to version $latest_version"
