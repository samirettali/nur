{
  lib,
  stdenvNoCC,
  fetchurl,
  appimageTools,
  makeWrapper,
  writeText,
  # Helium signs its helpers with the hardened runtime's library-validation
  # flag, which outranks the disable-library-validation entitlement the generic
  # helper already carries. AMFI then refuses Google's Widevine CDM because the
  # team IDs differ, and DRM playback fails. Upstream considers third-party CDMs
  # unsupported and points at re-signing the bundle instead:
  # https://github.com/imputnet/helium-macos/issues/296
  enableWidevine ? true,
}: let
  pname = "helium";
  version = "0.16.3.1";

  sources = {
    "aarch64-darwin" = fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_arm64-macos.dmg";
      hash = "sha256-TMJx0TBfCJNNlQC2clJa5fn1qi7UmYbYu8YlqZvYMiA=";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64.AppImage";
      hash = "sha256-FOU6WQLFPbpPLEuQJhasuxE4vDsB6cWIc0k9DAcghBk=";
    };
    "x86_64-darwin" = fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_x86_64-macos.dmg";
      hash = "sha256-S8TOy8Geuo/sh8AM107bJEZZKhu4ovvgpoICDvbD9Pw=";
    };
    "x86_64-linux" = fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
      hash = "sha256-k3CjrF45s7SizRof/X9eOnPKwkOB9c1AvBSmjj7ROIM=";
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

  # An ad-hoc signature without library validation. Chromium needs the JIT
  # entitlements to run at all under the hardened runtime, so re-signing has to
  # restore them rather than only drop the flag.
  entitlements = writeText "helium-entitlements.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>com.apple.security.cs.allow-jit</key>
      <true/>
      <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
      <true/>
      <key>com.apple.security.cs.disable-executable-page-protection</key>
      <true/>
      <key>com.apple.security.cs.disable-library-validation</key>
      <true/>
      <key>com.apple.security.cs.allow-dyld-environment-variables</key>
      <true/>
    </dict>
    </plist>
  '';

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

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications
      cp -r Helium.app $out/Applications/
      makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" $out/bin/helium

      runHook postInstall
    '';

    # Signed from the inside out, because codesign seals what it finds: a helper
    # re-signed after its framework would invalidate the framework's seal.
    # `rcodesign` cannot do this job — it merges the flags it is given into the
    # ones already in the signature, so library-validation survives. Only
    # `codesign --force` replaces them, and the system copy is as much of a
    # host dependency as the `hdiutil` above.
    fixupPhase =
      if enableWidevine
      then ''
        runHook preFixup

        app="$out/Applications/Helium.app"
        framework="$app/Contents/Frameworks/Helium Framework.framework"
        chmod -R u+w "$app"

        sign() {
          /usr/bin/codesign \
            --force \
            --sign - \
            --options runtime \
            --entitlements ${entitlements} \
            --timestamp=none \
            "$1"
        }

        for versionDir in "$framework/Versions/"*; do
          [ -L "$versionDir" ] && continue

          for helper in "$versionDir/Helpers/"*; do
            sign "$helper"
          done

          sign "$versionDir"
        done

        sign "$app"

        runHook postFixup
      ''
      else "";
  };
in
  if stdenvNoCC.hostPlatform.isDarwin
  then darwin
  else if stdenvNoCC.hostPlatform.isLinux
  then linux
  else throw "Unsupported platform: ${stdenvNoCC.hostPlatform.system}"
