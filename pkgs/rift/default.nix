{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${version}";
    hash = "sha256-7YSffWhF4ZqFuArWOrLKxXCzPLkTXSqlyJ9QeAi06u8=";
  };

  cargoHash = "sha256-AgHR8thBePobjqe2r4H53m6W0b6GEI5V7BK+gjDdU9A=";

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
