#!/usr/bin/env nix-shell
#!nix-shell -i bash -p git jq nix

set -euo pipefail

NUR_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$NUR_ROOT"

get_package_version() {
  local pkg="$1"

  nix eval --impure --raw --expr "let pkg = builtins.getAttr \"${pkg}\" (import ./. {}); in pkg.version or \"\"" 2>/dev/null || true
}

package_has_changes() {
  local pkg="$1"

  [[ -n "$(git status --porcelain -- "pkgs/$pkg")" ]]
}

echo "Scanning for packages with update scripts..."

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit or stash changes before running update-all.sh"
  exit 1
fi

packages=$(nix eval --json --impure --expr 'builtins.attrNames (import ./. {})' | jq -r '.[]')
excluded=("lib" "modules" "overlays")

for pkg in $packages; do
  for excluded_item in "${excluded[@]}"; do
    if [[ "$excluded_item" = "$pkg" ]]; then
      continue 2
    fi
  done

  update_script="$NUR_ROOT/pkgs/$pkg/update.sh"
  if [[ ! -f "$update_script" ]]; then
    echo "⚠️ $pkg has no update script at pkgs/$pkg/update.sh"
    continue
  fi

  if [[ ! -x "$update_script" ]]; then
    echo "⚠️ $pkg update script is not executable"
    continue
  fi

  old_version=$(get_package_version "$pkg")
  log_file=$(mktemp)

  echo "=== Updating $pkg ==="

  if "$update_script" >"$log_file" 2>&1; then
    new_version=$(get_package_version "$pkg")

    if package_has_changes "$pkg"; then
      if [[ -z "$old_version" || -z "$new_version" ]]; then
        echo "⚠️ $pkg changed files, but its version could not be determined"
        sed -n '1,200p' "$log_file"
        rm -f "$log_file"
        exit 1
      fi

      if [[ "$old_version" == "$new_version" ]]; then
        echo "⚠️ $pkg changed files, but its version stayed at $new_version"
        sed -n '1,200p' "$log_file"
        rm -f "$log_file"
        exit 1
      fi

      git add -A -- "pkgs/$pkg"
      git commit -m "$pkg: $old_version -> $new_version" >/dev/null
      echo "✅ Updated $pkg and committed $old_version -> $new_version"
    else
      echo "↔️ $pkg is already up-to-date at ${new_version:-$old_version}"
    fi

    if [[ -n "$(git status --porcelain)" ]]; then
      echo "Stopping because the update for $pkg left unrelated working tree changes"
      rm -f "$log_file"
      exit 1
    fi
  else
    echo "❌ Failed to update $pkg"
    sed -n '1,200p' "$log_file"

    if [[ -n "$(git status --porcelain)" ]]; then
      echo "Stopping because the working tree is dirty after the failed update"
      rm -f "$log_file"
      exit 1
    fi
  fi

  rm -f "$log_file"
done
