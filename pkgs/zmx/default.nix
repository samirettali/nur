{
  lib,
  stdenv,
  fetchFromGitHub,
  zig_0_15,
  callPackage,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "zmx";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "neurosnap";
    repo = "zmx";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bjYf5gb5OD1ZNcju5m3DPE1YuLM2iqIAu+3bwxm6pJ8=";
  };

  postConfigure = ''
    ln -s ${callPackage ./build.zig.zon.nix {zig = zig_0_15;}} $ZIG_GLOBAL_CACHE_DIR/p
  '';

  nativeBuildInputs = [zig_0_15];

  doCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Session persistence for terminal processes";
    homepage = "https://github.com/neurosnap/zmx";
    changelog = "https://github.com/neurosnap/zmx/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "zmx";
    platforms = lib.platforms.all;
  };
})
