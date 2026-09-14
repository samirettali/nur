{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "fluxctl";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "samirettali";
    repo = "fluxctl";
    rev = "v${version}";
    hash = "sha256-QFUqxL9EZYxD0KE2JoFjIT5OSmAGWWFQaHAT2hUQewg=";
  };

  # Standard library only, so there is nothing to vendor and the updater never
  # has to touch a vendorHash.
  vendorHash = null;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agent-friendly Miniflux CLI with machine-readable JSON output";
    homepage = "https://github.com/samirettali/fluxctl";
    changelog = "https://github.com/samirettali/fluxctl/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "fluxctl";
  };
}
