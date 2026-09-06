#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR/../.."
nix-update --version-regex 'v(.*)' --build firecrawl-cli
