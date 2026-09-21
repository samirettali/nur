{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "git-who";
  version = "1.3";

  src = fetchFromGitHub {
    owner = "sinclairtarget";
    repo = "git-who";
    rev = "v${version}";
    hash = "sha256-105UUQBAB0/5d0xEoKOr7xwKvXy42RgyOHVFFArXHQ4=";
  };

  vendorHash = "sha256-e2P7szjtAn4EFTy+eGi/9cYf/Raw/7O+PbYEOD8i3Hs=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=v${version}"
  ];

  # The test suite runs against git repositories vendored as submodules, which
  # the source tarball does not carry.
  doCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Git blame for file trees";
    homepage = "https://github.com/sinclairtarget/git-who";
    changelog = "https://github.com/sinclairtarget/git-who/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "git-who";
  };
}
