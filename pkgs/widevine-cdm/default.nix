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
  version = "4.10.3050.0";

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
        url = "https://dl.google.com/release2/chrome_component/ad7g6ajom265ggbvq6rrx4nb22ra_4.10.3050.0/oimompecagnajdejgnnjijobebaeigek_4.10.3050.0_mac_arm64_ad6r3hn3iuwofjkdi4widjwuy3na.crx3";
        hash = "sha256-EaLGRPG6+zzNtX+E37W9kHvYWXSUKNgHo19Vo/dMbyE=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://dl.google.com/release2/chrome_component/ac46odufbnrvxcdn4wur6s2o4kjq_4.10.3050.0/oimompecagnajdejgnnjijobebaeigek_4.10.3050.0_mac64_acvag6gyzleiuk2y32voj4ebbeja.crx3";
        hash = "sha256-DwbYScUXirG6c0z+LR9apM66KrkqTwKOKW6PrUTUQZM=";
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
