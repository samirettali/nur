#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest release information for sst/opencode..."
latest_release_data=$(curl --silent --fail "https://api.github.com/repos/sst/opencode/releases/latest")

latest_version=$(echo "$latest_release_data" | jq -r .tag_name | sed 's/^v//')
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "opencode is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating opencode from $current_version to $latest_version"

# Update version in default.nix
sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

declare -A platform_map
platform_map=(
  ["aarch64-darwin"]="darwin-arm64"
  ["aarch64-linux"]="linux-arm64"
  ["x86_64-darwin"]="darwin-x64"
  ["x86_64-linux"]="linux-x64"
)

for nix_platform in "${!platform_map[@]}"; do
  gh_platform=${platform_map[$nix_platform]}
  url="https://github.com/sst/opencode/releases/download/v${latest_version}/opencode-${gh_platform}.zip"

  echo "Fetching hash for ${nix_platform}..."
  hash_base64=$(nix-prefetch-url --type sha256 "$url")
  sri_hash="sha256-${hash_base64}"

  # Use sed to update the hash for the specific platform
  sed -i -E "/\"${nix_platform}\"/,/\};/s|([[:space:]]*hash = \").*(\";)|\1${sri_hash}\2|" "$DEFAULT_NIX_FILE"
done

echo "Successfully updated opencode to version $latest_version in $DEFAULT_NIX_FILE"