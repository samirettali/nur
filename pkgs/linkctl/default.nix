{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "linkctl";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "samirettali";
    repo = "linkctl";
    rev = "v${version}";
    hash = "sha256-z1cGsa7XUCWs8ysDPqBoVF95zQcZgbx26K3WS+YrWyk=";
  };

  # Standard library only, so there is nothing to vendor and the updater never
  # has to touch a vendorHash.
  vendorHash = null;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agent-friendly linkding CLI with machine-readable JSON output";
    homepage = "https://github.com/samirettali/linkctl";
    changelog = "https://github.com/samirettali/linkctl/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "linkctl";
  };
}
