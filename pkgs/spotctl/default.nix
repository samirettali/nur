{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "spotctl";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "samirettali";
    repo = "spotctl";
    rev = "v${version}";
    hash = "sha256-/Lu6kS9pu5GOY028iFsTCqP4i/+QHgh+WkGC1U2gfXM=";
  };

  vendorHash = null;

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
