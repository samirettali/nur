#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl git jq nix

set -euo pipefail

NUR_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$NUR_ROOT"

get_package_version() {
  local pkg="$1"

  nix eval --impure --raw --expr "let pkg = builtins.getAttr \"${pkg}\" (import ./. {}); in pkg.version or \"\"" 2>/dev/null || true
}

get_package_metadata() {
  local pkg="$1"

  nix eval --json --impure --expr "let
    pkg = builtins.getAttr \"${pkg}\" (import ./. {});
    meta = pkg.meta or {};
  in {
    homepage = meta.homepage or \"\";
    changelog = meta.changelog or \"\";
  }" 2>/dev/null || printf '{"homepage":"","changelog":""}\n'
}

package_has_changes() {
  local pkg="$1"

  [[ -n "$(git status --porcelain -- "pkgs/$pkg")" ]]
}

print_log_excerpt() {
  local log_file="$1"

  head -n 200 "$log_file"
}

extract_github_repo_url() {
  local value repo

  for value in "$@"; do
    if [[ "$value" =~ ^https://github\.com/([^/]+)/([^/#?]+) ]]; then
      repo="${BASH_REMATCH[2]}"
      repo="${repo%.git}"
      printf 'https://github.com/%s/%s\n' "${BASH_REMATCH[1]}" "$repo"
      return 0
    fi
  done

  return 1
}

url_exists() {
  local url="$1"

  curl \
    --silent \
    --show-error \
    --location \
    --head \
    --fail \
    --connect-timeout 5 \
    --max-time 10 \
    "$url" >/dev/null 2>&1
}

find_first_existing_url() {
  local url

  for url in "$@"; do
    if [[ -n "$url" ]] && url_exists "$url"; then
      printf '%s\n' "$url"
      return 0
    fi
  done

  return 1
}

build_commit_body() {
  local pkg="$1"
  local old_version="$2"
  local new_version="$3"
  local metadata homepage changelog repo_url compare_url release_url

  metadata=$(get_package_metadata "$pkg")
  homepage=$(jq -r '.homepage // ""' <<<"$metadata")
  changelog=$(jq -r '.changelog // ""' <<<"$metadata")

  repo_url=$(extract_github_repo_url "$homepage" "$changelog" || true)
  compare_url=""
  release_url=""

  if [[ -n "$repo_url" ]]; then
    compare_url=$(find_first_existing_url \
      "$repo_url/compare/v${old_version}...v${new_version}" \
      "$repo_url/compare/${old_version}...${new_version}" \
      "$repo_url/compare/V${old_version}...V${new_version}" \
      || true)

    if [[ -n "$changelog" ]] && [[ "$changelog" == https://github.com/* ]]; then
      release_url="$changelog"
    else
      release_url=$(find_first_existing_url \
        "$repo_url/releases/tag/v${new_version}" \
        "$repo_url/releases/tag/${new_version}" \
        "$repo_url/releases/tag/V${new_version}" \
        || true)
    fi
  fi

  printf 'Automated package update.\n\n'
  printf 'Version:\n'
  printf -- '- old: %s\n' "$old_version"
  printf -- '- new: %s\n' "$new_version"

  if [[ -n "$repo_url" || -n "$compare_url" || -n "$release_url" ]]; then
    printf '\nUpstream:\n'
    [[ -n "$repo_url" ]] && printf -- '- repository: %s\n' "$repo_url"
    [[ -n "$compare_url" ]] && printf -- '- compare: %s\n' "$compare_url"
    [[ -n "$release_url" ]] && printf -- '- release: %s\n' "$release_url"
  fi
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
        print_log_excerpt "$log_file"
        rm -f "$log_file"
        exit 1
      fi

      if [[ "$old_version" == "$new_version" ]]; then
        echo "⚠️ $pkg changed files, but its version stayed at $new_version"
        print_log_excerpt "$log_file"
        rm -f "$log_file"
        exit 1
      fi

      git add -A -- "pkgs/$pkg"

      commit_message_file=$(mktemp)
      {
        printf '%s\n\n' "$pkg: $old_version -> $new_version"
        build_commit_body "$pkg" "$old_version" "$new_version"
      } >"$commit_message_file"
      git commit -F "$commit_message_file" >/dev/null
      rm -f "$commit_message_file"

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
    print_log_excerpt "$log_file"

    if [[ -n "$(git status --porcelain)" ]]; then
      echo "Stopping because the working tree is dirty after the failed update"
      rm -f "$log_file"
      exit 1
    fi
  fi

  rm -f "$log_file"
done
