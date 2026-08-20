#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest release information for anthropics/claude-code..."
latest_release_data=$(curl --silent --fail "https://api.github.com/repos/anthropics/claude-code/releases/latest")

latest_version=$(echo "$latest_release_data" | jq -r .tag_name | sed 's/^v//')
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
	echo "claude-code is already up-to-date at version $latest_version"
	exit 0
fi

echo "Updating claude-code from $current_version to $latest_version"

# Update version in default.nix
sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

# Every release ships SHASUMS256.txt, so the hashes come from one small file
# instead of four ~300 MB downloads.
shasums=$(curl --silent --fail --location \
	"https://github.com/anthropics/claude-code/releases/download/v${latest_version}/SHASUMS256.txt")

declare -A platform_map
platform_map=(
	["aarch64-darwin"]="darwin-arm64"
	["aarch64-linux"]="linux-arm64"
	["x86_64-darwin"]="darwin-x64"
	["x86_64-linux"]="linux-x64"
)

for nix_platform in "${!platform_map[@]}"; do
	asset="claude-${platform_map[$nix_platform]}.tar.gz"

	hex_hash=$(awk -v asset="$asset" '$2 == asset { print $1 }' <<<"$shasums")
	if [[ -z "$hex_hash" ]]; then
		echo "No checksum for $asset in SHASUMS256.txt" >&2
		exit 1
	fi

	sri_hash=$(nix hash convert --hash-algo sha256 --to sri "$hex_hash")

	# Update the hash for this platform only
	sed -i -E "/\"${nix_platform}\"/,/\};/s|([[:space:]]*hash = \").*(\";)|\1${sri_hash}\2|" "$DEFAULT_NIX_FILE"
done

echo "Successfully updated claude-code to version $latest_version in $DEFAULT_NIX_FILE"
