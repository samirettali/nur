{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grok-cli";
  version = "1.0.77";

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
        hash = "sha256-GXxmpj5axG4HRQsMoh0UHOZlBQpBIYDxhdrfrhx6Wyo=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-aarch64";
        hash = "sha256-sw7uFKZWEk7zydqFd7Xng+8s/6vrK2ecXEljPnfu1XQ=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-macos-x86_64";
        hash = "sha256-dyj3nqcTrmek+kc23PgI9rOG2WQiAq6h32lQc/pWZ1o=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-x86_64";
        hash = "sha256-twKVCqWCfYVeSTJ4q2IVpOD1vOtbumxiQ6n1XN0UOwo=";
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
