{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grok-cli";
  version = "0.2.101";

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
        hash = "sha256-hDFTjb2ZN5JA9Vi0i3ecZR1miwbXk8hzEa1TLEOVpOI=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-aarch64";
        hash = "sha256-TC1uezENUN2p8bsBQ/BplQ26toAhw46QIq77cyq9Mxk=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-macos-x86_64";
        hash = "sha256-iEqp4lINhTWQJ711cQI4FlEAyI2HkEbjSTGqcDhmQh0=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-x86_64";
        hash = "sha256-JVYpnN7Tf4HlTAJCDPp/Gi35/qtypEWGmg9VluFDszM=";
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
