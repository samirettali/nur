#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

latest_version=$(curl --silent --fail \
  "https://api.github.com/repos/imputnet/helium-linux/releases/latest" \
  | jq -r .tag_name)

current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "helium is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating helium from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

declare -A repositories assets
repositories=(
  ["aarch64-darwin"]="helium-macos"
  ["aarch64-linux"]="helium-linux"
  ["x86_64-darwin"]="helium-macos"
  ["x86_64-linux"]="helium-linux"
)
assets=(
  ["aarch64-darwin"]="helium_${latest_version}_arm64-macos.dmg"
  ["aarch64-linux"]="helium-${latest_version}-arm64.AppImage"
  ["x86_64-darwin"]="helium_${latest_version}_x86_64-macos.dmg"
  ["x86_64-linux"]="helium-${latest_version}-x86_64.AppImage"
)

for nix_platform in \
  aarch64-darwin \
  aarch64-linux \
  x86_64-darwin \
  x86_64-linux; do
  url="https://github.com/imputnet/${repositories[$nix_platform]}/releases/download/${latest_version}/${assets[$nix_platform]}"

  echo "Fetching hash for $nix_platform..."
  hash_base64=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null)
  src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
  sed -i -E "/\"${nix_platform}\"/,/\};/s|([[:space:]]*hash = \").*(\";)|\1${src_hash}\2|" "$DEFAULT_NIX_FILE"
done

echo "Successfully updated helium to version $latest_version"
