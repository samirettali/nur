{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "claude-code";
  version = "2.1.237";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;
  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [autoPatchelfHook];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm 755 ./claude $out/bin/claude

    runHook postInstall
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-darwin-arm64.tar.gz";
        hash = "sha256-zFxzR2cn2KgjLquUnBnjzRraKj5RdnuVTszRq3UslWM=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-linux-arm64.tar.gz";
        hash = "sha256-qpm1Zy7FrBug5VNqtMqyPfAIACLfJa4LhOimeNu6vlo=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-darwin-x64.tar.gz";
        hash = "sha256-mFD1UHqZWWzz+WuzPm628UeOsPEGOpfptyhYrr2spXY=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-linux-x64.tar.gz";
        hash = "sha256-/hxH4zCccxtsmzglmWA983hLANZaIjb0bIZ/xVQ2rfo=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "Agentic coding tool that lives in your terminal";
    longDescription = ''
      Claude Code is Anthropic's agentic coding tool. It understands your
      codebase, edits files, runs terminal commands and handles entire
      workflows from the terminal.

      This package installs the official native build. The binary lives in the
      read-only Nix store, so the built-in auto-updater cannot replace it: set
      DISABLE_AUTOUPDATER=1 and bump the package instead.
    '';
    homepage = "https://github.com/anthropics/claude-code";
    changelog = "https://github.com/anthropics/claude-code/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.unfree;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    mainProgram = "claude";
  };
})
