{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grok-cli";
  version = "0.2.77";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/grok"
    ln -s grok "$out/bin/agent"

    runHook postInstall
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-macos-aarch64";
        hash = "sha256-quSSDDlSyX4ScZAjZCfd29dnjYXQmlOoHP1wgHLkH9k=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-aarch64";
        hash = "sha256-SRPCW4Zc4n9cv2UgSkg8ErHnRF4xKOjL28qycq4yhDc=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-macos-x86_64";
        hash = "sha256-Jib5AzB2cfOwFE1UT0XPLUmZ/08cUCHPIgWPkIHoY0k=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-x86_64";
        hash = "sha256-mmczoW7vRpLYMLFGyd7IBCzcEkqXvIzAEWly92d+RnA=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "Grok CLI coding agent";
    homepage = "https://x.ai/cli";
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    mainProgram = "grok";
  };
})
