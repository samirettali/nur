{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grok-cli";
  version = "1.0.60";

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
        hash = "sha256-mA+tHcs3cBAc8FzhtT/O6ixHBqaVek+5AAocBTocAlI=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-aarch64";
        hash = "sha256-Zlwoa2Z2DrGl5xmfYPuAKKWg0pDMjpzey6bJskr3uGI=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-macos-x86_64";
        hash = "sha256-ZCwRWXPDI8ecQwsn76qUdVothH0MzCPtltSRg/7yb0c=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-x86_64";
        hash = "sha256-EOavZLJHJPwQdMNz6Qa5rRIREARN3cvZetQ8OiX5bV8=";
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
