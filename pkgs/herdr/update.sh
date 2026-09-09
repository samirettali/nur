#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
NUR_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)

# herdr is pinned to master, not to the latest release: the multi-machine
# feature set keeps landing there and the tags lag behind it. The version is
# therefore <cargo version>-unstable-<commit date>, the nixpkgs convention for
# an unreleased pin.

echo "Fetching master HEAD for herdrdev/herdr..."
head_json=$(curl --silent --fail \
	-H "Accept: application/vnd.github+json" \
	"https://api.github.com/repos/herdrdev/herdr/commits/master")
latest_rev=$(jq -r .sha <<<"$head_json")
commit_date=$(jq -r '.commit.committer.date | split("T")[0]' <<<"$head_json")
current_rev=$(grep -E '^ *rev = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_rev" == "$current_rev" ]]; then
	echo "herdr is already up-to-date at $latest_rev"
	exit 0
fi

url="https://github.com/herdrdev/herdr/archive/${latest_rev}.tar.gz"
cargo_version=$(curl --silent --fail "https://raw.githubusercontent.com/herdrdev/herdr/${latest_rev}/Cargo.toml" |
	grep -m1 -E '^version = "' | cut -d '"' -f 2)
latest_version="${cargo_version}-unstable-${commit_date}"
current_version=$(grep -E '^ *version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

echo "Updating herdr from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"
sed -i -E "s/^( *rev = \").*(\";)/\1$latest_rev\2/" "$DEFAULT_NIX_FILE"

echo "Fetching source hash..."
hash_base64=$(nix-prefetch-url --unpack --type sha256 "$url" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E "s|( *hash = \").*(\";)|\1${src_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Fetching cargo hash..."
sed -i -E 's|( *cargoHash = ").*(";)|\1sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\2|' "$DEFAULT_NIX_FILE"
cargo_hash=$(nix build --impure --expr "let repo = import ${NUR_ROOT} {}; in repo.herdr.cargoDeps" 2>&1 | awk '/got:/ { print $NF }' | tail -n1 || true)
if [[ -z "$cargo_hash" ]]; then
	echo "Failed to determine cargo hash" >&2
	exit 1
fi
sed -i -E "s|( *cargoHash = \").*(\";)|\1${cargo_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Successfully updated herdr to $latest_version ($latest_rev)"
