{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "eqmac";
  version = "1.8.15";

  src = fetchurl {
    url = "https://github.com/bitgapp/eqMac/releases/download/v${finalAttrs.version}/eqMac.dmg";
    hash = "sha256-IL0KslVlXdHiLL7JARfIpQlfjndPMvCkZppHVRPH8I0=";
  };

  strictDeps = true;

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack

    mnt=$(mktemp -d)
    /usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$mnt" "$src"
    cp -r "$mnt/eqMac.app" .
    /usr/bin/hdiutil detach "$mnt"

    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r eqMac.app $out/Applications/

    mkdir -p $out/bin
    ln -s $out/Applications/eqMac.app/Contents/MacOS/eqMac $out/bin/eqMac

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "macOS system-wide audio equalizer and volume mixer";
    homepage = "https://github.com/bitgapp/eqMac";
    changelog = "https://github.com/bitgapp/eqMac/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    maintainers = with lib.maintainers; [];
    platforms = ["aarch64-darwin" "x86_64-darwin"];
    mainProgram = "eqMac";
  };
})
