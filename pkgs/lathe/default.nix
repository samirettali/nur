{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "lathe";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "devenjarvis";
    repo = "lathe";
    rev = "v${version}";
    hash = "sha256-nZr6RsOxyFu7JXUCT4UARiS52RD8dzGXC/VqXPlMzl8=";
  };

  vendorHash = "sha256-yA4FB2e0kaj2Fq1zGRNM/C5pWhhOCT6VU3Y/KpicxL8=";

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
