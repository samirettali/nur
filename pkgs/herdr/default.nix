{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  callPackage,
  runCommand,
  zig_0_15,
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
  version = "0.9.0-unstable-2026-09-10";
  rev = "90e947a6e26e02f10ec7f1694c4eb5b78a86406b";

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr";
    inherit rev;
    hash = "sha256-9jBtNBphxaqNU1IvEtqfMLjohyJ+iW02OA6HeOUM/Nc=";
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

  cargoHash = "sha256-CW/SF/cAPDv47gS5B7XbVZEE6LC9F1a2I1TLTJ4AWdw=";

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
    ZIG = lib.getExe zig_0_15;
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
