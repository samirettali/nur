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
  version = "0.7.5";

  src = fetchFromGitHub {
    owner = "ogulcancelik";
    repo = "herdr";
    rev = "v${version}";
    hash = "sha256-3BA8eredGku+vsL2Af7sUf43QiArR5XTHNrI+X11vFM=";
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

  cargoHash = "sha256-lWnc0Ka0hp7bbm+dkKKj22Dbk+Cwrld86romXs3lzBs=";

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
    changelog = "https://github.com/ogulcancelik/herdr/releases/tag/v${version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "herdr";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
