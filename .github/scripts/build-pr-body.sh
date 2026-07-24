#!/usr/bin/env bash
#
# Build the pull request body for an automated package bump.
#
# Usage: build-pr-body.sh <commit-ish>
#
# Reads the "key: value" links that update-all.sh writes into the bump commit
# message and, when the package lives on GitHub, expands the compare range into
# an inline commit list via the API. Requires GH_TOKEN for the API call; without
# it the commit list is skipped and only the links are emitted.

set -euo pipefail

COMMIT_LIMIT=30

commit="${1:?usage: build-pr-body.sh <commit-ish>}"

body=$(git log -1 --format=%b "$commit")

metadata_value() {
  local key="$1"

  grep -m1 -E "^${key}: " <<<"$body" | cut -d ' ' -f 2- || true
}

homepage=$(metadata_value homepage)
repository=$(metadata_value repository)
compare_url=$(metadata_value compare)
release_url=$(metadata_value release)

# Turn https://github.com/<owner>/<repo>/compare/<base>...<head> into the API
# path that returns the commits in that range.
compare_api_path() {
  local url="$1"

  if [[ "$url" =~ ^https://github\.com/([^/]+)/([^/]+)/compare/(.+)$ ]]; then
    printf 'repos/%s/%s/compare/%s\n' \
      "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    return 0
  fi

  return 1
}

# Markdown bullets, oldest first, matching the order of the compare page.
# Merges are dropped: they carry no changelog value in a version range.
render_commits() {
  local api_path="$1"
  local payload total shown

  payload=$(gh api --paginate "$api_path" 2>/dev/null) || return 1

  payload=$(jq -s '{commits: (map(.commits) | add // [])}' <<<"$payload")

  total=$(jq '[.commits[] | select((.parents | length) < 2)] | length' <<<"$payload")
  if [[ "$total" -eq 0 ]]; then
    return 1
  fi

  printf '## Commits\n\n'

  jq -r --argjson limit "$COMMIT_LIMIT" '
    [.commits[] | select((.parents | length) < 2)][:$limit][]
    | "- [`\(.sha[0:7])`](\(.html_url)) \(.commit.message | split("\n")[0])"
  ' <<<"$payload"

  shown=$((total > COMMIT_LIMIT ? COMMIT_LIMIT : total))
  if [[ "$total" -gt "$shown" ]]; then
    printf '\n_…and %s more_\n' "$((total - shown))"
  fi
}

commits_rendered=""
if [[ -n "$compare_url" ]] && api_path=$(compare_api_path "$compare_url"); then
  commits_rendered=$(render_commits "$api_path" || true)
fi

if [[ -n "$commits_rendered" ]]; then
  printf '%s\n' "$commits_rendered"
else
  printf '_No upstream changelog available._\n'
fi

if [[ -n "$compare_url" || -n "$release_url" || -n "$repository" || -n "$homepage" ]]; then
  printf '\n## Links\n\n'

  if [[ -n "$compare_url" ]]; then
    printf -- '- [Compare](%s)\n' "$compare_url"
  fi

  if [[ -n "$release_url" ]]; then
    printf -- '- [Release notes](%s)\n' "$release_url"
  fi

  if [[ -n "$repository" ]]; then
    printf -- '- [Repository](%s)\n' "$repository"
  fi

  if [[ -n "$homepage" && "$homepage" != "$repository" ]]; then
    printf -- '- [Homepage](%s)\n' "$homepage"
  fi
fi
