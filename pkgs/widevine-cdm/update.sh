#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

APP_ID="oimompecagnajdejgnnjijobebaeigek"

# Chrome's component updater speaks Omaha v3 over POST. It answers with the
# pinned download URL, the version and the SHA-256 of the package, so nothing
# here has to prefetch a hash. The response starts with a 5-byte `)]}'\n`
# anti-XSSI prefix that has to go before jq sees it.
component_for() {
  local arch="$1"

  curl --silent --fail \
    --header 'Content-Type: application/json' \
    --data @- \
    "https://update.googleapis.com/service/update2/json" <<EOF | tail -c +6
{
  "request": {
    "@os": "mac",
    "@updater": "chrome",
    "acceptformat": "crx3",
    "protocol": "3.1",
    "updater": "chrome",
    "arch": "$arch",
    "os": {"arch": "$arch", "platform": "Mac OS X", "version": "15.0.0"},
    "prodversion": "151.0.7922.169",
    "updaterversion": "151.0.7922.169",
    "app": [
      {
        "appid": "$APP_ID",
        "version": "0.0.0.0",
        "enabled": true,
        "updatecheck": {}
      }
    ]
  }
}
EOF
}

latest_version=$(component_for arm64 | jq -r '.response.app[0].updatecheck.manifest.version')
current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
  echo "Could not read the latest Widevine CDM version from the component updater" >&2
  exit 1
fi

if [[ "$latest_version" == "$current_version" ]]; then
  echo "widevine-cdm is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating widevine-cdm from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

declare -A architectures
architectures=(
  ["aarch64-darwin"]="arm64"
  ["x86_64-darwin"]="x64"
)

for nix_platform in aarch64-darwin x86_64-darwin; do
  response=$(component_for "${architectures[$nix_platform]}")

  url=$(jq -r '
    .response.app[0].updatecheck as $check
    | ($check.urls.url | map(.codebase) | map(select(startswith("https://"))) | first)
      + $check.manifest.packages.package[0].name
  ' <<<"$response")
  sha256=$(jq -r '.response.app[0].updatecheck.manifest.packages.package[0].hash_sha256' <<<"$response")

  if [[ -z "$url" || "$url" == "null" || -z "$sha256" || "$sha256" == "null" ]]; then
    echo "Could not read the $nix_platform package from the component updater" >&2
    exit 1
  fi

  src_hash=$(nix hash convert --hash-algo sha256 --to sri "$sha256")

  sed -i -E "/\"${nix_platform}\"/,/\};/{
    s|([[:space:]]*url = \").*(\";)|\1${url}\2|
    s|([[:space:]]*hash = \").*(\";)|\1${src_hash}\2|
  }" "$DEFAULT_NIX_FILE"
done

echo "Successfully updated widevine-cdm to version $latest_version"
