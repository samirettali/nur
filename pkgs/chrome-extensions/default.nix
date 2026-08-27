{
  lib,
  stdenvNoCC,
  fetchurl,
}:
# The CRX files for the extensions I run, pinned to the versioned blob URLs the
# Chrome Web Store hands out. Chromium forks without the Web Store — Helium,
# ungoogled-chromium — ignore an external extension that carries only an update
# URL, but install one that points at a CRX on disk, which is what these are for.
let
  entries = lib.importJSON ./extensions.json;

  crx = id: entry:
    fetchurl {
      name = "${entry.name}-${entry.version}.crx";
      inherit (entry) url hash;
    };
in
  stdenvNoCC.mkDerivation {
    pname = "chrome-extensions";
    # Nine extensions, nine upstream versions: the date of the last refresh is
    # the only version this set as a whole can have. update.sh moves it.
    version = "2026-08-27";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      ${lib.concatStringsSep "\n"
        (lib.mapAttrsToList (id: entry: "cp ${crx id entry} $out/${id}.crx") entries)}

      runHook postInstall
    '';

    passthru = {
      inherit entries;
      updateScript = ./update.sh;
    };

    meta = {
      description = "Pinned Chrome Web Store extensions for Chromium forks without the Web Store";
      homepage = "https://chromewebstore.google.com";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [binaryBytecode];
      maintainers = with lib.maintainers; [];
      platforms = lib.platforms.all;
    };
  }
