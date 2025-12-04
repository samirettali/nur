{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "1.0.132";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;
  nativeBuildInputs = [unzip];

  unpackPhase = ''
    unpackFile $src
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm 755 ./opencode $out/bin/opencode

    runHook postInstall
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-darwin-arm64.zip";
        hash = "sha256-gUIb0O/P8woPCNTpnbA5uKH8vVOC+wnVu0JLflH1aZI=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-linux-arm64.zip";
        hash = "sha256-zoQ9PBvPkMSmPMbF5IWSkaKzYmKWjhJu/zkGY6E/HYM=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-darwin-x64.zip";
        hash = "sha256-NaT9dbDurKHuzAKI8nekjETe5LQTnFlBJI+XvAsrPhs=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-linux-x64.zip";
        hash = "sha256-QNaXuAie3oXtA+NavN5aqwCnDARAAXQk0FmgyN6FEr8=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "The AI coding agent built for the terminal";
    longDescription = ''
      OpenCode is a terminal-based agent that can build anything.
      It combines a TypeScript/JavaScript core with a Go-based TUI
      to provide an interactive AI coding experience.
    '';
    homepage = "https://github.com/sst/opencode";
    license = lib.licenses.mit;
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    mainProgram = "opencode";
  };
})
