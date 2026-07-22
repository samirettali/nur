{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "spotctl";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "samirettali";
    repo = "spotctl";
    rev = "v${version}";
    hash = "sha256-3MfRQPAYjVfOz5nqb3QQLZxP/kFimoVc8DeWb9+KTU4=";
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
