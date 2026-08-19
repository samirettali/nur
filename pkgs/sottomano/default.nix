{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sottomano";
  version = "0.1.0";

  src = fetchurl {
    url = "https://github.com/samirettali/sottomano/releases/download/v${finalAttrs.version}/Sottomano-${finalAttrs.version}.dmg";
    hash = "sha256-QhjzqOwRe3j4zHi/80M9jOP9rr/Ft0icr97DW6ODzQI=";
  };

  strictDeps = true;

  sourceRoot = ".";

  # The image is notarised and stapled, so it mounts without a prompt. Read-only
  # and not browsable: nothing here needs the Finder to see it.
  unpackPhase = ''
    runHook preUnpack

    mnt=$(mktemp -d)
    /usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$mnt" "$src"
    cp -r "$mnt/Sottomano.app" .
    /usr/bin/hdiutil detach "$mnt"

    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  # No link in $out/bin: it is an LSUIElement application driven by a hotkey,
  # and running the binary from a shell is not how it is meant to be started.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r Sottomano.app $out/Applications/

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "macOS launcher driven by one leader key";
    homepage = "https://github.com/samirettali/sottomano";
    changelog = "https://github.com/samirettali/sottomano/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    maintainers = with lib.maintainers; [];
    # arm64 only: the disk image carries no Intel slice.
    platforms = ["aarch64-darwin"];
  };
})
