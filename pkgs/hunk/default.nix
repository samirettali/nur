{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hunk";
  version = "0.21.1";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm 755 ./hunk $out/bin/hunk

    runHook postInstall
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-darwin-arm64.tar.gz";
        hash = "sha256-x42IH/PmgljKa+faINeG7cBZk6U1zFu6LkopjdwYAbo=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-linux-arm64.tar.gz";
        hash = "sha256-HTHfw4K5pN+cBF6yOewkj2HEFh3TLsfKqrhZPVWp7KY=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-darwin-x64.tar.gz";
        hash = "sha256-kMLcftiHkIu1WG3J7JBqDhWw5TpDxZWWjoaGO2KtSWw=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-linux-x64.tar.gz";
        hash = "sha256-x9HiO6T/tsozMHl+nwyC262lDjz+G3GfQZR0fyy8oSI=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "Review-first terminal diff viewer for agentic coders";
    homepage = "https://github.com/modem-dev/hunk";
    changelog = "https://github.com/modem-dev/hunk/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    mainProgram = "hunk";
  };
})
