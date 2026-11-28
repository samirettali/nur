{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "quartz";
  version = "5.3.1";

  src = fetchFromGitHub {
    owner = "jackyzha0";
    repo = "quartz";
    rev = "v${version}";
    hash = "sha256-pJjLt2tJEgxNT/0vozMifLV3Fom9IGM4VhfziBVwL8U=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-GXsxeJrltUNWlLtvgrrLm2XkBtVc/uPGBGeEkqTMqqc=";

  dontBuild = true;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "A fast, batteries-included static-site generator that transforms Markdown content into fully functional websites";
    homepage = "https://github.com/jackyzha0/quartz";
    changelog = "https://github.com/jackyzha0/quartz/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "quartz";
  };
}
