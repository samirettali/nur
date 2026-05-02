#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

latest_version=$(curl --silent --fail \
  "https://api.github.com/repos/openai/codex/releases/latest" \
  | jq -r .tag_name | sed 's/^rust-v//')

current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "codex is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating codex from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

declare -A platform_map
platform_map=(
  ["aarch64-darwin"]="aarch64-apple-darwin"
  ["aarch64-linux"]="aarch64-unknown-linux-musl"
  ["x86_64-darwin"]="x86_64-apple-darwin"
  ["x86_64-linux"]="x86_64-unknown-linux-musl"
)

for nix_platform in "${!platform_map[@]}"; do
  release_platform=${platform_map[$nix_platform]}
  url="https://github.com/openai/codex/releases/download/rust-v${latest_version}/codex-${release_platform}.tar.gz"

  echo "Fetching hash for ${nix_platform}..."
  hash_base64=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null)
  sri_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")

  sed -i -E "/\"${nix_platform}\"/,/\};/s|([[:space:]]*hash = \").*(\";)|\1${sri_hash}\2|" "$DEFAULT_NIX_FILE"
done

echo "Successfully updated codex to version $latest_version"
