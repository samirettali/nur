{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "git-sync";
  version = "0.21.0";

  src = fetchFromGitHub {
    owner = "AkashRajpurohit";
    repo = "git-sync";
    rev = "v${version}";
    hash = "sha256-Nbig7NNzXY2ezVeUflrrltMgfQJYtrRJG9LvIm7jRfo=";
  };

  vendorHash = "sha256-Ed1aSYAVsF8cPc+GrQDlcl4a18qxNAW4ms98SEEn/8g=";

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/AkashRajpurohit/git-sync/pkg/version.Version=v${version}"
    "-X=github.com/AkashRajpurohit/git-sync/pkg/version.Build=1970-01-01T00:00:00Z"
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "A simple tool to backup and sync your git repositories";
    homepage = "https://github.com/AkashRajpurohit/git-sync";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "git-sync";
  };
}
