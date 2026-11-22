{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "quartz";
  version = "5.2.0";

  src = fetchFromGitHub {
    owner = "jackyzha0";
    repo = "quartz";
    rev = "v${version}";
    hash = "sha256-D9yWt/th55jnv/gnOl+9elnhZqYFrTQMS19XYX+vhnQ=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-cdNhmcj+mBxaT8Qkpj8OWsyU0kFyYbUfK0cootk43qQ=";

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
