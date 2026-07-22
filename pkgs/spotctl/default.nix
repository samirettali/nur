{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "spotctl";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "samirettali";
    repo = "spotctl";
    rev = "v${version}";
    hash = "sha256-NZYCOPJK16sHq4nHT6XGQItlxIJrzBNQcYdwPHjGtqc=";
  };

  vendorHash = "sha256-ZG+eQhOHW5J1WLm2WZ57ywXA+NobgMorRJkR2Mkb2fY=";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agent-friendly Spotify CLI with machine-readable JSON output";
    homepage = "https://github.com/samirettali/spotctl";
    changelog = "https://github.com/samirettali/spotctl/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "spotctl";
  };
}
