#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq nix

set -euo pipefail

echo "Scanning for packages with updateScript..."

# Get all package names from the NUR
packages=$(nix eval --json --impure --expr 'builtins.attrNames (import ./. {})' | jq -r '.[]')
excluded=( "lib" "modules" "overlays" )

for pkg in $packages; do
    if [[ "${excluded[@]}" =~ "$pkg" ]]; then
        continue
    fi

  update_script=$(nix eval --impure --expr "(import ./. {}).$pkg.passthru.updateScript or null" 2>/dev/null)
    if [[ -z "$update_script" || "$update_script" == "null" ]]; then
        echo "⚠️ $pkg has no update script"
        continue
    fi

    if [[ ! -f "${update_script}" ]]; then
        echo "⚠️ $pkg update script is not a file"
        continue
    fi

    if [[ ! -x "${update_script}" ]]; then
        echo "⚠️ $pkg update script is not executable"
        continue
    fi

    tput sc

    echo -n "=== Updating $pkg ==="

    if $update_script 2&>/dev/null; then
        # clean line by deleting everying using escape sequence
        tput rc
        tput el
        echo "✅ Successfully updated $pkg"
    else
        tput rc
        tput el
        echo "❌ Failed to update $pkg"
    fi
done
