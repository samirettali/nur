{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hunk";
  version = "0.10.0";

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
        hash = "sha256-cdiwcZPevnbhlpsHzPeRVsb5WQdunaNlTCKh+XwarUU=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-linux-arm64.tar.gz";
        hash = "sha256-epaG0urTx3nqr2mIClkDLzrxf+gOZE4EDyC0YyEPq8M=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-darwin-x64.tar.gz";
        hash = "sha256-70O4DI3+7ZuZstem8QeiL/qrj9M65nYVflqzqUlpnSY=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-linux-x64.tar.gz";
        hash = "sha256-ND3Kb1u0B5O+joNCvE4LzJjYpSFnt5QWDFGmuAmYns8=";
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
