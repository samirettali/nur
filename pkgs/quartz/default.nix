{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "quartz";
  version = "5.1.0";

  src = fetchFromGitHub {
    owner = "jackyzha0";
    repo = "quartz";
    rev = "v${version}";
    hash = "sha256-iCk2QZqIgLGKdh1kKLK+ayq8PLbVTP5Oee8VKxp0n6s=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-36sFu+u8gpKqilbyyxhcqzpleTktCwUrNHr9WpIdIgU=";

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
