#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

latest_version=$(curl -fsSL "https://x.ai/cli/stable" || curl -fsSL "https://storage.googleapis.com/grok-build-public-artifacts/cli/stable")
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "grok-cli is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating grok-cli from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

declare -A platform_map
platform_map=(
  ["aarch64-darwin"]="macos-aarch64"
  ["aarch64-linux"]="linux-aarch64"
  ["x86_64-darwin"]="macos-x86_64"
  ["x86_64-linux"]="linux-x86_64"
)

for nix_platform in "${!platform_map[@]}"; do
  upstream_platform=${platform_map[$nix_platform]}
  url="https://x.ai/cli/grok-${latest_version}-${upstream_platform}"

  echo "Fetching hash for ${nix_platform}..."
  hash_base64=$(nix-prefetch-url --type sha256 "$url")
  sri_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")

  sed -i -E "/\"${nix_platform}\"/,/\};/s|([[:space:]]*hash = \").*(\";)|\1${sri_hash}\2|" "$DEFAULT_NIX_FILE"
done

echo "Successfully updated grok-cli to version $latest_version in $DEFAULT_NIX_FILE"
