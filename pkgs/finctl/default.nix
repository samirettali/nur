{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "finctl";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "samirettali";
    repo = "finctl";
    rev = "v${version}";
    hash = "sha256-Sx6qgYI/fsqwGaVDamUQZCfMKWc85vRhYQD/n5n8qQY=";
  };

  # Standard library only, so there is nothing to vendor and the updater never
  # has to touch a vendorHash.
  vendorHash = null;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agent-friendly finance CLI with machine-readable JSON output";
    homepage = "https://github.com/samirettali/finctl";
    changelog = "https://github.com/samirettali/finctl/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "finctl";
  };
}
