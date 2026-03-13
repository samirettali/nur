{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gastown";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "gastown";
    rev = "v${version}";
    hash = "sha256-1F7kEjKD+62+VeTTozuBzJukOLPd/WUpsoRha2rs+I8=";
  };

  vendorHash = "sha256-8SdvSASP+bJjMooqEQvkCzG+J6CbsK+HCQulrPnJZ1Y=";

  subPackages = [
    "cmd/gt"
    "cmd/gt-proxy-client"
    "cmd/gt-proxy-server"
  ];

  doCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Gas Town - multi-agent workspace manager";
    homepage = "https://github.com/steveyegge/gastown";
    changelog = "https://github.com/steveyegge/gastown/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "gastown";
  };
}
