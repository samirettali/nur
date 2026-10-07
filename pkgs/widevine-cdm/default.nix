{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
# The Widevine CDM Chrome would download through its component updater.
# Chromium forks that keep `enable_widevine` but have no component updater —
# Helium, ungoogled-chromium — create an empty `WidevineCdm` directory in the
# profile and never fill it, so DRM playback fails until the CDM is put there by
# hand. Google serves the component on its own, which is why this does not have
# to carve the CDM out of a full Chrome install.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "widevine-cdm";
  version = "4.10.3112.0";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
    or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;
  nativeBuildInputs = [unzip];

  dontConfigure = true;
  dontBuild = true;

  # A CRX3 is a zip with a signed header in front of it. unzip reads it anyway
  # but reports the leading bytes as an error, so the extraction is checked by
  # what it produced instead of by the exit status.
  unpackPhase = ''
    runHook preUnpack

    unzip -q $src -d cdm || true
    test -f cdm/manifest.json

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r cdm/manifest.json cdm/_platform_specific $out/
    cp -r cdm/LICENSE $out/ 2>/dev/null || true

    runHook postInstall
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://edgedl.me.gvt1.com/edgedl/release2/chrome_component/ac7kldzznoqpelvhlm22cvg6iw7q_4.10.3112.0/oimompecagnajdejgnnjijobebaeigek_4.10.3112.0_mac_arm64_acwuvzzk4g3lgkvyjjsbyjwqnxoq.crx3";
        hash = "sha256-a/MtEGMNWuvhriqvtRD0OAE0fDDQEpMnZOY7VRMyWvQ=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://edgedl.me.gvt1.com/edgedl/release2/chrome_component/acvkbk6uzwaavliybbd7ayuuab5a_4.10.3112.0/oimompecagnajdejgnnjijobebaeigek_4.10.3112.0_mac64_adtfufbhdjipnvjmwyq2z6yuhyaa.crx3";
        hash = "sha256-flWttnQzG6mImEmFcN4ZXK7FqXbsHUixkskbLG4au00=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "Widevine Content Decryption Module for Chromium forks without a component updater";
    homepage = "https://www.widevine.com/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    maintainers = with lib.maintainers; [];
    platforms = builtins.attrNames finalAttrs.passthru.sources;
  };
})
