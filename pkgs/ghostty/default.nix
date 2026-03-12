{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ghostty";
  version = "1.3.0";

  src = fetchurl {
    url = "https://release.files.ghostty.org/${finalAttrs.version}/Ghostty.dmg";
    hash = "sha256-U/6Y5wmCEYAIwDuf2/XfJlUip/22vfoY630NTNMdDMU=";
  };

  strictDeps = true;

  sourceRoot = ".";

  unpackPhase = ''
    mnt=$(mktemp -d)
    /usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$mnt" "$src"
    cp -r "$mnt/Ghostty.app" .
    /usr/bin/hdiutil detach "$mnt"
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r Ghostty.app $out/Applications/

    mkdir -p $out/bin
    ln -s $out/Applications/Ghostty.app/Contents/MacOS/ghostty $out/bin/ghostty

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Fast, feature-rich, and cross-platform terminal emulator";
    homepage = "https://ghostty.org";
    changelog = "https://github.com/ghostty-org/ghostty/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    platforms = ["aarch64-darwin" "x86_64-darwin"];
    mainProgram = "ghostty";
  };
})
