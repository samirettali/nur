{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "t3code";
  version = "0.1.13";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;
  nativeBuildInputs = [unzip];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  # The bundle is named after the release channel ("T3 Code (Alpha).app"), so
  # match it by glob rather than pinning a name that changes on its own.
  installPhase = ''
    runHook preInstall

    app=$(ls -d *.app)

    mkdir -p $out/Applications $out/bin
    cp -R "$app" $out/Applications/
    ln -s "$out/Applications/$app/Contents/MacOS/$(basename "$app" .app)" $out/bin/t3code

    runHook postInstall
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/pingdotgg/t3code/releases/download/v${finalAttrs.version}/T3-Code-${finalAttrs.version}-arm64.zip";
        hash = "sha256-f0b9KwfJDm/ttiP0clvEAwym6GzoL2mkha1JKMqJNQ0=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/pingdotgg/t3code/releases/download/v${finalAttrs.version}/T3-Code-${finalAttrs.version}-x64.zip";
        hash = "sha256-tTXgI1FofrF2lwA8/E5Vtm9u4DEU8R34aDRyTiUUXiA=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "Desktop control surface for coding agents running on your machine";
    homepage = "https://github.com/pingdotgg/t3code";
    changelog = "https://github.com/pingdotgg/t3code/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    maintainers = with lib.maintainers; [];
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    mainProgram = "t3code";
  };
})
