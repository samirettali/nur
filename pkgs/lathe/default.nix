{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "lathe";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "devenjarvis";
    repo = "lathe";
    rev = "v${version}";
    hash = "sha256-X7EYZH5sotrCVHmJwd6KP6nlLsN/R4lqP28q+QqAqKE=";
  };

  vendorHash = "sha256-3QV/ocKpCu2cmefLBCf4ZAAgFbN3500To5qpMinm+uM=";

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/devenjarvis/lathe/internal/buildinfo.Version=v${version}"
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Generate, store, serve, verify, and extend hands-on technical tutorials";
    homepage = "https://github.com/devenjarvis/lathe";
    changelog = "https://github.com/devenjarvis/lathe/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "lathe";
  };
}
