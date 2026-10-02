{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "0.6.3";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${version}";
    hash = "sha256-PCCX+fUgyrbtMqGosedGy2VfLoNEpBbRNwuFWAtNb/M=";
  };

  cargoHash = "sha256-vRRsl5fyy5vyIUWoZMc+2Kyuee2Dk05MZh/n3na9SWo=";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Tiling window manager for macOS";
    homepage = "https://github.com/acsandmann/rift";
    changelog = "https://github.com/acsandmann/rift/releases/tag/v${version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [];
    mainProgram = "rift";
    platforms = lib.platforms.darwin;
  };
}
