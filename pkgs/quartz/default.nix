{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "quartz";
  version = "4.5.2";

  src = fetchFromGitHub {
    owner = "jackyzha0";
    repo = "quartz";
    rev = "v${version}";
    hash = "sha256-A6ePeNmcsbtKVnm7hVFOyjyc7gRYvXuG0XXQ6fvTLEw=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-xxK9qy04m1olekOJIyYJHfdkYFzpjsgcfyFPuKsHpKE=";

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
