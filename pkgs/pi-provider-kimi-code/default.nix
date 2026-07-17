{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchpatch,
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

  patches = [
    (fetchpatch {
      url = "https://github.com/Leechael/pi-provider-kimi-code/commit/1d8b05f6f3421fc440b919d5e21e956aaa9ab657.patch";
      hash = "sha256-wESWsQS8HuXZnRnhtHwyaLDv7V2HTqPRs23a8qqyddk=";
    })
  ];

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
    cp -R . $out/
    chmod -R u+w $out

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
