{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cmux";
  version = "0.64.9";

  src = fetchurl {
    url = "https://github.com/manaflow-ai/cmux/releases/download/v${finalAttrs.version}/cmux-macos.dmg";
    hash = "sha256-L/UX02N97RoGV0VyhXCbrEMeVJZPAhyXIYiySzr3Q7g=";
  };

  strictDeps = true;

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack

    mnt=$(mktemp -d)
    /usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$mnt" "$src"
    cp -r "$mnt/cmux.app" .
    /usr/bin/hdiutil detach "$mnt"

    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r cmux.app $out/Applications/

    mkdir -p $out/bin
    ln -s $out/Applications/cmux.app/Contents/Resources/bin/cmux $out/bin/cmux

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Ghostty-based macOS terminal with vertical tabs and notifications for AI coding agents";
    homepage = "https://github.com/manaflow-ai/cmux";
    changelog = "https://github.com/manaflow-ai/cmux/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [];
    platforms = ["aarch64-darwin" "x86_64-darwin"];
    mainProgram = "cmux";
  };
})
