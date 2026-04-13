#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
NUR_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)

echo "Fetching latest release information for roberte777/zesh..."
# Tags are in the format zesh-v<version>
latest_version=$(curl --silent --fail "https://api.github.com/repos/roberte777/zesh/releases/latest" | jq -r .tag_name | sed 's/^zesh-v//')
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
	echo "zesh is already up-to-date at version $latest_version"
	exit 0
fi

echo "Updating zesh from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

url="https://github.com/roberte777/zesh/archive/refs/tags/zesh-v${latest_version}.tar.gz"
echo "Fetching source hash..."
hash_base64=$(nix-prefetch-url --unpack --type sha256 "$url" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E "s|( *hash = \").*(\";)|\1${src_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Fetching cargo hash..."
sed -i -E 's|( *cargoHash = ").*(";)|\1sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\2|' "$DEFAULT_NIX_FILE"
cargo_hash=$(nix build --impure --expr "let repo = import ${NUR_ROOT} {}; in repo.zesh.cargoDeps" 2>&1 | awk '/got:/ { print $NF }' | tail -n1 || true)
if [[ -z "$cargo_hash" ]]; then
	echo "Failed to determine cargo hash" >&2
	exit 1
fi
sed -i -E "s|( *cargoHash = \").*(\";)|\1${cargo_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Successfully updated zesh to version $latest_version"
