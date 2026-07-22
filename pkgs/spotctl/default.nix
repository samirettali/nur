{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "spotctl";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "samirettali";
    repo = "spotctl";
    rev = "v${version}";
    hash = "sha256-RNUtmUezQmWF7GXl2Bl3iM1+hlwcY4XxvE4ECPh7Mt0=";
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
