{
  lib,
  stdenvNoCC,
  fetchurl,
  appimageTools,
  makeWrapper,
}: let
  pname = "helium";
  version = "0.15.2.1";

  sources = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_arm64-macos.dmg";
      hash = "sha256-+onoZkK37fwg0upK0A03xGmMORC0e8+ozeHqN/2j/X8=";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64.AppImage";
      hash = "sha256-73KXJ2H8FGNt5VTg/9cdkbRfRVgafxwRRe4DQlbM408=";
    };
    "x86_64-darwin" = fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_x86_64-macos.dmg";
      hash = "sha256-df5GUDBW2+TvytHFrarMRLNFTrGPwXXwD3FreqqIDlY=";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
      hash = "sha256-Sn3MWsvqZw5YUYVKrEkJLW1gFQ1Sr+whEsCiFxYNvgg=";
    };
  };

  src =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  passthru = {
    inherit sources;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Private, fast, and honest web browser";
    homepage = "https://helium.computer";
    changelog = "https://github.com/imputnet/helium-linux/releases/tag/${version}";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    maintainers = with lib.maintainers; [];
    platforms = builtins.attrNames sources;
    mainProgram = "helium";
  };

  linux = let
    appImageContents = appimageTools.extract {
      inherit pname version src;
    };
  in
    appimageTools.wrapType2 {
      inherit
        pname
        version
        src
        passthru
        meta
        ;

      extraInstallCommands = ''
        install -Dm444 ${appImageContents}/helium.desktop $out/share/applications/helium.desktop
        install -Dm444 ${appImageContents}/product_logo_256.png \
          $out/share/icons/hicolor/256x256/apps/helium.png
      '';
    };

  darwin = stdenvNoCC.mkDerivation {
    inherit
      pname
      version
      src
      passthru
      meta
      ;

    strictDeps = true;
    nativeBuildInputs = [makeWrapper];
    sourceRoot = ".";

    unpackPhase = ''
      runHook preUnpack

      mnt=$(mktemp -d)
      /usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$mnt" "$src"
      cp -r "$mnt/Helium.app" .
      /usr/bin/hdiutil detach "$mnt"

      runHook postUnpack
    '';

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r Helium.app $out/Applications/
      makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" $out/bin/helium

      runHook postInstall
    '';
  };
in
  if stdenvNoCC.hostPlatform.isDarwin
  then darwin
  else if stdenvNoCC.hostPlatform.isLinux
  then linux
  else throw "Unsupported platform: ${stdenvNoCC.hostPlatform.system}"
