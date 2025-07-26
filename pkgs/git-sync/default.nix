{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "git-sync";
  version = "0.19.0";

  src = fetchFromGitHub {
    owner = "AkashRajpurohit";
    repo = "git-sync";
    rev = "v${version}";
    hash = "sha256-MHr4X8bPrbm9YxBSWJ9bHCChlcMFTsUPDliPVzlUFZY=";
  };

  vendorHash = "sha256-VJLdAkONyJiyQTtrZ9xwVXTqpkbHsIbVgOAu2RA62ao=";

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/AkashRajpurohit/git-sync/pkg/version.Version=v${version}"
    "-X=github.com/AkashRajpurohit/git-sync/pkg/version.Build=1970-01-01T00:00:00Z"
  ];

  meta = {
    description = "A simple tool to backup and sync your git repositories";
    homepage = "https://github.com/AkashRajpurohit/git-sync";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "git-sync";
  };
}
