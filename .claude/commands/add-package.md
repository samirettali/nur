# Add NUR Package

Add a new package derivation to this NUR repository.

The user will provide a GitHub URL (or package name). Follow the steps below based on the package type.

---

## Step 1 — Gather information

Fetch the GitHub repo page to determine:
- Latest release version and tag format (e.g. `v1.0.0` vs `V1.0.0`)
- License
- Description and main binary name
- Language / build system (Go, Rust, pre-built binaries, etc.)
- Minimum language version required (check `go.mod`, `Cargo.toml`, or release assets)

---

## Step 2 — Create the derivation

Create `pkgs/<name>/default.nix` following the appropriate template below.
Then wire it up in `default.nix`:
```nix
<name> = pkgs.callPackage ./pkgs/<name> {};
```

### Pre-built binaries (e.g. opencode)

Use `stdenvNoCC.mkDerivation` with `fetchurl` per platform. Follow `pkgs/opencode/default.nix` exactly as the template:
- Use `finalAttrs` pattern
- Put sources in `passthru.sources` keyed by Nix system strings (`aarch64-darwin`, `x86_64-linux`, etc.)
- Fetch the source hash with `nix-prefetch-url` for each platform URL
- Set `platforms = builtins.attrNames finalAttrs.passthru.sources`

### Go packages

Use `buildGoModule`. Follow `pkgs/git-sync/default.nix` as the template:
```nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "<name>";
  version = "<version>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "v${version}";  # adjust prefix if the tag uses a capital V or no prefix
    hash = "<sri-hash>";
  };

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  meta = {
    description = "...";
    homepage = "https://github.com/<owner>/<repo>";
    changelog = "https://github.com/<owner>/<repo>/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "<binary-name>";
  };
}
```

- If `go.mod` requires a Go version not provided by the default toolchain, add:
  ```nix
  { ..., go_1_XX }: (buildGoModule.override { go = go_1_XX; }) rec { ... }
  ```
  Check available versions with `nix eval 'nixpkgs#go_1_XX.version'`.
- If tests fail in the Nix sandbox (filesystem, network, OS-specific calls), add `doCheck = false`.
- If the package installs shell scripts alongside binaries (complex layout), use `postInstall` to set up `$out/share/<name>/` with the full tree and write real wrapper scripts in `$out/bin/` using `printf` — not symlinks — so `BASH_SOURCE[0]` resolves correctly.

### Rust packages

Use `rustPlatform.buildRustPackage`. Follow `pkgs/tredis/default.nix` as the template:
```nix
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "<name>";
  version = "<version>";

  src = fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "v${version}";
    hash = "<sri-hash>";
  };

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  meta = {
    description = "...";
    homepage = "https://github.com/<owner>/<repo>";
    changelog = "https://github.com/<owner>/<repo>/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "<binary-name>";
  };
}
```

- If the `Cargo.lock` uses version 4 and the build fails with "requires `-Znext-lockfile-bump`", the flake's nixpkgs pin is too old — run `nix flake update`.
- Do not add `useFetchCargoVendor = true`; it is the default in nixpkgs 25.05+.

### Other languages

- **Node.js**: use `buildNpmPackage` or `mkYarnPackage`
- **Python**: use `python3Packages.buildPythonApplication` with `pyproject = true` for modern packages
- **Zig**: use `stdenv.mkDerivation` with `zigBuildHook`
- In all cases, look for an existing package in nixpkgs doing the same thing and follow that pattern

---

## Step 3 — Get the real hashes

Fetch the source hash:
```bash
nix-prefetch-url --unpack "https://github.com/<owner>/<repo>/archive/refs/tags/v<version>.tar.gz" 2>/dev/null \
  | xargs -I{} nix hash convert --hash-algo sha256 --to sri {}
```

For the dependency hash (`vendorHash` / `cargoHash`), use the fake placeholder first, then build to get the real value from the error output:
```bash
nix build .#<name>
# error will print: got: sha256-<real-hash>
```
Substitute the real hash into `default.nix`.

---

## Step 4 — Add an update script

Create `pkgs/<name>/update.sh` (executable) following the pattern of `pkgs/tredis/update.sh` (Rust) or `pkgs/go-qo/update.sh` (Go):

```bash
#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"
NUR_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)

latest_version=$(curl --silent --fail \
  "https://api.github.com/repos/<owner>/<repo>/releases/latest" \
  | jq -r .tag_name | sed 's/^v//')  # adjust prefix stripping to match the tag format

current_version=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

if [[ "$latest_version" == "$current_version" ]]; then
  echo "<name> is already up-to-date at version $latest_version"
  exit 0
fi

echo "Updating <name> from $current_version to $latest_version"

sed -i -E "s/^( *version = \").*(\";)/\1$latest_version\2/" "$DEFAULT_NIX_FILE"

hash_base64=$(nix-prefetch-url --unpack --type sha256 \
  "https://github.com/<owner>/<repo>/archive/refs/tags/v${latest_version}.tar.gz" 2>/dev/null)
src_hash=$(nix hash convert --hash-algo sha256 --to sri "$hash_base64")
sed -i -E "s|( *hash = \").*(\";)|\1${src_hash}\2|" "$DEFAULT_NIX_FILE"

# Replace with the appropriate hash field name:
# cargoHash for Rust, vendorHash for Go
sed -i -E 's|( *cargoHash = \").*(\";)|\1sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\2|' "$DEFAULT_NIX_FILE"
dep_hash=$(nix build "${NUR_ROOT}#<name>" 2>&1 | grep "got:" | awk '{print $NF}' || true)
if [[ -z "$dep_hash" ]]; then
  echo "Failed to determine dependency hash" >&2
  exit 1
fi
sed -i -E "s|( *cargoHash = \").*(\";)|\1${dep_hash}\2|" "$DEFAULT_NIX_FILE"

echo "Successfully updated <name> to version $latest_version"
```

For pre-built binaries, the update script should update the version and re-fetch each platform URL hash individually (see `pkgs/opencode/update.sh`).

---

## Checklist

- [ ] `pkgs/<name>/default.nix` created with correct hashes
- [ ] Entry added to `default.nix`
- [ ] `nix build .#<name>` succeeds
- [ ] `pkgs/<name>/update.sh` created and executable (`chmod +x`)
