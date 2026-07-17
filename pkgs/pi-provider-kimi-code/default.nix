{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-provider-kimi-code";
  version = "0.6.7";

  src = fetchFromGitHub {
    owner = "Leechael";
    repo = "pi-provider-kimi-code";
    tag = "v${finalAttrs.version}";
    hash = "sha256-q8A0h72ZKIcl5DRmUjymWI/F1z6KqdartpPoqFuctEI=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDeps = importNpmLock {
    npmRoot = finalAttrs.src;
    package = lib.importJSON (finalAttrs.src + "/package.json");
    packageLock = lib.importJSON ./package-lock.json;
  };
  npmConfigHook = importNpmLock.npmConfigHook;
  npmInstallFlags = ["--omit=dev"];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R $src/. $out/
    chmod -R u+w $out
    cp ${./package-lock.json} $out/package-lock.json
    cp -R node_modules $out/

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Kimi Code provider extension for the Pi coding agent";
    homepage = "https://github.com/Leechael/pi-provider-kimi-code";
    changelog = "https://github.com/Leechael/pi-provider-kimi-code/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
  };
})
