{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "quartz";
  version = "5.2.2";

  src = fetchFromGitHub {
    owner = "jackyzha0";
    repo = "quartz";
    rev = "v${version}";
    hash = "sha256-rKPprK7R1JGKs/dTk8Qwa8YVLZaf5N7jyLv4d5m+b3k=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-6EgDnkmQK6OiTHpM8nNY+3NRJN55gCc6lG8PEpH6bH0=";

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
