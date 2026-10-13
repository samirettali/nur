{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  callPackage,
  runCommand,
  zig_0_16,
  zstd,
  pkg-config,
  git,
  cctools ? null,
  xcbuild ? null,
}:
let
  # Tracks master rather than the release tag: the multi-machine work landed in
  # 0.9.0 and its fixes keep arriving on master, so the release lags what is
  # usable. update.sh follows master's HEAD.
  version = "0.9.4-unstable-2026-10-13-dec3156";
  rev = "dec3156a6f795450d1b1b634f0a0d5cefd056ee3";

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr";
    inherit rev;
    hash = "sha256-LBO0EDarOuxWNbUwFidUGIvCThOy2sPWBsHFk61gkN0=";
  };

  zigDeps = callPackage "${src}/vendor/libghostty-vt/build.zig.zon.nix" {
    name = "herdr-libghostty-vt-zig-cache";
    inherit zstd;
    linkFarm =
      name: entries:
      runCommand name { } ''
        mkdir -p $out
        ${lib.concatMapStringsSep "\n" (entry: ''
          cp -rL ${entry.path} $out/${entry.name}
        '') entries}
      '';
  };
in
rustPlatform.buildRustPackage {
  pname = "herdr";
  inherit version src;

  cargoHash = "sha256-IPsukFZI+VARH2e4I3dNe6pD8f3NaC3WtLiylfl/qQA=";

  nativeBuildInputs = [
    git
    pkg-config
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    cctools
    xcbuild
  ];

  env = {
    LIBGHOSTTY_VT_OPTIMIZE = "ReleaseFast";
    LIBGHOSTTY_VT_SIMD = "true";
    LIBGHOSTTY_VT_ZIG_SYSTEM_DIR = zigDeps;
    ZIG = lib.getExe zig_0_16;
  };

  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"
  '';

  doCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Terminal workspace manager for AI coding agents";
    homepage = "https://herdr.dev";
    changelog = "https://github.com/herdrdev/herdr/commits/master";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "herdr";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
