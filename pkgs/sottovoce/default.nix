{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sottovoce";
  version = "0.3.0";

  src = fetchurl {
    url = "https://github.com/samirettali/sottovoce/releases/download/v${finalAttrs.version}/Sottovoce-${finalAttrs.version}.dmg";
    hash = "sha256-+95+0wVBwO6Y6qy7TK0PGxx/4wXA8o9OrLLjzQ1iXS4=";
  };

  strictDeps = true;

  sourceRoot = ".";

  # The image is notarised and stapled, so it mounts without a prompt. Read-only
  # and not browsable: nothing here needs the Finder to see it.
  unpackPhase = ''
    runHook preUnpack

    mnt=$(mktemp -d)
    /usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$mnt" "$src"
    cp -r "$mnt/Sottovoce.app" .
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
    cp -r Sottovoce.app $out/Applications/

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "macOS menu bar dictation app";
    homepage = "https://github.com/samirettali/sottovoce";
    changelog = "https://github.com/samirettali/sottovoce/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    maintainers = with lib.maintainers; [];
    # arm64 only: the disk image carries no Intel slice.
    platforms = ["aarch64-darwin"];
  };
})
