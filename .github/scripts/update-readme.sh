#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq nix
#
# Regenerate the package table in README.md from the derivations wired up in
# default.nix. Rewrites the block between the BEGIN/END markers and leaves the
# rest of the file alone.
#
# Versions are deliberately left out: they change on almost every update-all.sh
# run and would keep the README perpetually out of date.

set -euo pipefail

NUR_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." &>/dev/null && pwd)
cd "$NUR_ROOT"

BEGIN_MARKER='<!-- BEGIN PACKAGES -->'
END_MARKER='<!-- END PACKAGES -->'

readme="$NUR_ROOT/README.md"

if ! grep -qF "$BEGIN_MARKER" "$readme" || ! grep -qF "$END_MARKER" "$readme"; then
  echo "README.md is missing the $BEGIN_MARKER / $END_MARKER markers" >&2
  exit 1
fi

# meta.description is free text and may contain a pipe, which would break the
# table, so escape it.
packages_json=$(nix eval --impure --json --expr '
  let
    set = import ./. {};
    skip = [ "lib" "modules" "overlays" ];
    names = builtins.filter (n: !(builtins.elem n skip)) (builtins.attrNames set);
    info = name:
      let
        pkg = set.${name};
        meta = pkg.meta or {};
      in {
        inherit name;
        description = meta.description or "";
        homepage = meta.homepage or "";
      };
  in map info names
')

table=$(jq -r '
  sort_by(.name)
  | .[]
  | "| \(if .homepage == "" then .name else "[\(.name)](\(.homepage))" end) | \(.description | gsub("\\|"; "\\\\|")) |"
' <<<"$packages_json")

count=$(jq 'length' <<<"$packages_json")

generated=$(
  printf '%s\n\n' "$BEGIN_MARKER"
  printf '| Package | Description |\n'
  printf '| --- | --- |\n'
  printf '%s\n' "$table"
  printf '\n%s\n' "$END_MARKER"
)

# Splice the generated block back in, replacing whatever sat between the
# markers before.
updated=$(mktemp)
awk \
  -v begin_marker="$BEGIN_MARKER" \
  -v end_marker="$END_MARKER" \
  -v block="$generated" '
  $0 == begin_marker { print block; skipping = 1; next }
  $0 == end_marker { skipping = 0; next }
  !skipping { print }
' "$readme" >"$updated"

mv "$updated" "$readme"

echo "Wrote $count packages to README.md"
