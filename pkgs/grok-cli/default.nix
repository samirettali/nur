{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grok-cli";
  version = "0.2.73";

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
        hash = "sha256-n+J/zydlXcWILWmjA/YYenWanCSfbHF169h96zoNFhc=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-aarch64";
        hash = "sha256-ab3THmm1aH9VEnRwWOpR2dzoJIQbjJes0H2fwBb6grM=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-macos-x86_64";
        hash = "sha256-NRx9N49CzU+QjP5vQ7bWakJMPoeksholu/bR+/JUH9o=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-x86_64";
        hash = "sha256-6gBfOYMXFA8Kz7pfeHx1GZNnH4DAVdyrreFfHfp2Gx0=";
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
