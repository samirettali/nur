{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-mcp-adapter";
  version = "2.11.0";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JjYS9tPSoVuubdmHTqTNNYfDJOc9CBPvVbIxvdJWi7M=";
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
    description = "MCP adapter extension for the Pi coding agent";
    homepage = "https://github.com/nicobailon/pi-mcp-adapter";
    changelog = "https://github.com/nicobailon/pi-mcp-adapter/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
  };
})
