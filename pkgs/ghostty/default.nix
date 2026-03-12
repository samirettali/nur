{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ghostty";
  version = "2026-03-12";

  src = fetchurl {
    url = "https://github.com/ghostty-org/ghostty/releases/download/tip/ghostty-macos-universal.zip";
    hash = "sha256-TWYB2l78zhxPd7EdYmA+lLmDXEc1gY1FVG+CxYrzIEs=";
  };

  strictDeps = true;
  nativeBuildInputs = [unzip];

  sourceRoot = ".";

  unpackPhase = ''
    unzip $src
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r Ghostty.app $out/Applications/

    # Re-sign with an ad-hoc signature since the Nix store path differs from
    # the original signing path, causing macOS Launch Constraint Violations.
    /usr/bin/codesign --force --deep --sign - "$out/Applications/Ghostty.app"

    mkdir -p $out/bin
    ln -s $out/Applications/Ghostty.app/Contents/MacOS/ghostty $out/bin/ghostty

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Fast, feature-rich, and cross-platform terminal emulator";
    homepage = "https://ghostty.org";
    changelog = "https://github.com/ghostty-org/ghostty/releases/tag/tip";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    platforms = ["aarch64-darwin" "x86_64-darwin"];
    mainProgram = "ghostty";
  };
})
