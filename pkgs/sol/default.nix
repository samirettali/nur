{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sol";
  version = "2.1.347";

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

    mkdir -p $out/Applications $out/bin
    cp -R Sol.app $out/Applications/
    ln -s $out/Applications/Sol.app/Contents/MacOS/sol $out/bin/sol

    runHook postInstall
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/ospfranco/sol/releases/download/${finalAttrs.version}/${finalAttrs.version}.zip";
        hash = "sha256-S1xJdtjCSwH0Sa14Rx6PU13kGOjtEaL7mYgnD4XEPP4=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/ospfranco/sol/releases/download/${finalAttrs.version}/${finalAttrs.version}.zip";
        hash = "sha256-S1xJdtjCSwH0Sa14Rx6PU13kGOjtEaL7mYgnD4XEPP4=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "MacOS launcher and command palette";
    homepage = "https://github.com/ospfranco/sol";
    changelog = "https://github.com/ospfranco/sol/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    mainProgram = "sol";
  };
})
