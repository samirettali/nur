#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

latest_version=$(curl --silent --fail \
  "https://api.github.com/repos/samirettali/spotctl/releases/latest" \
  | jq -r .tag_name | sed 's/^v//')
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "spotctl is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating spotctl from $current_version to $latest_version"
sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

url="https://github.com/samirettali/spotctl/archive/refs/tags/v${latest_version}.tar.gz"
hash_base64=$(nix-prefetch-url --unpack --type sha256 "$url" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E "s|( *hash = \").*(\";)|\1${src_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Successfully updated spotctl to version $latest_version"
