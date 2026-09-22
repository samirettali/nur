{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "1.18.32";

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
        hash = "sha256-+mQ/k0AcE1CNjVE3gOVM6cwBID1QERS+m4jWJAi4EB8=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-linux-arm64.zip";
        hash = "sha256-VoRht9TYwZhlyX6aEQLmEwScYDnQH+dyFU3oc8GGWEA=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-darwin-x64.zip";
        hash = "sha256-okvxBJk4L4hV4Z0qCBuGg+SrmcfCr/sy3ImxfIoAzNY=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-linux-x64.zip";
        hash = "sha256-MEbgQE/cYPuAMH56R4JLoHR3NkF4pNCbqoVISW3W1Ds=";
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
