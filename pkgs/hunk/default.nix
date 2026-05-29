{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hunk";
  version = "0.14.0";

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
        hash = "sha256-tG9kRvm69mBONw1kz8N3ZONcXKLu1Ja1N+SBfQSSxvk=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-linux-arm64.tar.gz";
        hash = "sha256-Bbq5e7Y524gLgiwgLPJZeHWY49Z5UX52W8u64WVbY+U=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-darwin-x64.tar.gz";
        hash = "sha256-/CK0xqZUKkRwcoR12MTHcrLTgxRrmxcy9Yni8QIay10=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/modem-dev/hunk/releases/download/v${finalAttrs.version}/hunkdiff-linux-x64.tar.gz";
        hash = "sha256-f8/R0OAaJGSJRq7b9XHiYlZgHnLTxuz2GmfrY0SWgOg=";
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
