#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest release information for ospfranco/sol..."
latest_version=$(curl --silent --fail "https://api.github.com/repos/ospfranco/sol/releases/latest" | jq -r .tag_name)
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
	echo "sol is already up-to-date at version $latest_version"
	exit 0
fi

echo "Updating sol from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

url="https://github.com/ospfranco/sol/releases/download/${latest_version}/${latest_version}.zip"

echo "Fetching hash for ${url}..."
hash_base64=$(nix-prefetch-url --type sha256 "$url")
sri_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")

sed -i -E "s|( *hash = \").*(\";)|\1${sri_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Successfully updated sol to version $latest_version"
