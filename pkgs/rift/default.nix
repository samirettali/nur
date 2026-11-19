{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "0.8.5";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${version}";
    hash = "sha256-5DBFfe4WIbFRg1hCg61h33QMvORrLkA6iHBSmUA2LJo=";
  };

  cargoHash = "sha256-UbXSHPfv69Pq7X/JWAwK4mf2Kx9Reap35ubgUzKrnME=";

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
