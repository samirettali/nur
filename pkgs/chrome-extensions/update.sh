#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
EXTENSIONS_FILE="$SCRIPT_DIR/extensions.json"

# The Chrome Web Store update endpoint answers a pretended fresh install
# (`v=0.0.0.0`) with a pinned blob URL, the version and the SHA-256 of the CRX.
# Asking for the CRX URL directly would give an unversioned redirect, whose hash
# changes under us whenever the extension is republished.
extension_metadata() {
  local id="$1"

  curl --silent --fail --get \
    --data-urlencode "response=updatecheck" \
    --data-urlencode "prodversion=9999.0" \
    --data-urlencode "acceptformat=crx3" \
    --data-urlencode "x=id=$id&v=0.0.0.0&uc" \
    "https://clients2.google.com/service/update2/crx"
}

attribute() {
  local xml="$1" name="$2"

  sed -n -E "s/.*[[:space:]]${name}=\"([^\"]*)\".*/\1/p" <<<"$xml" | head -n1
}

updated=0
extensions=$(jq -c '.' "$EXTENSIONS_FILE")

for id in $(jq -r 'keys[]' <<<"$extensions"); do
  name=$(jq -r --arg id "$id" '.[$id].name' <<<"$extensions")
  current_version=$(jq -r --arg id "$id" '.[$id].version // ""' <<<"$extensions")

  xml=$(extension_metadata "$id" | tr '>' '>\n')
  version=$(attribute "$xml" version)
  url=$(attribute "$xml" codebase)
  sha256=$(attribute "$xml" hash_sha256)

  if [[ -z "$version" || -z "$url" || -z "$sha256" ]]; then
    echo "Could not read $name ($id) from the Chrome Web Store" >&2
    exit 1
  fi

  if [[ "$version" == "$current_version" ]]; then
    echo "↔️ $name is already up-to-date at $version"
    continue
  fi

  echo "Updating $name from ${current_version:-none} to $version"

  hash=$(nix hash convert --hash-algo sha256 --to sri "$sha256")
  extensions=$(jq -c \
    --arg id "$id" \
    --arg version "$version" \
    --arg url "$url" \
    --arg hash "$hash" \
    '.[$id] += {version: $version, url: $url, hash: $hash}' \
    <<<"$extensions")
  updated=1
done

if [[ "$updated" -eq 0 ]]; then
  echo "chrome-extensions is already up-to-date"
  exit 0
fi

jq --sort-keys '.' <<<"$extensions" >"$EXTENSIONS_FILE"

# Nine extensions with nine versions have no single version between them, and
# the repository's update.sh insists that a changed package changed its version.
# The date of the last refresh is the only honest answer.
today=$(date -u +%Y-%m-%d)
sed -i -E "s/^( *version = \").*(\";)/\1$today\2/" "$DEFAULT_NIX_FILE"

echo "Successfully refreshed chrome-extensions on $today"
