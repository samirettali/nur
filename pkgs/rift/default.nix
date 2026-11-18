{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "0.8.4";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${version}";
    hash = "sha256-mgl09uli0qHPnCzmv8KRq1unNgXbmoCjfZX3tFn76Lo=";
  };

  cargoHash = "sha256-MpsI9Pr4jZMQjW3WAS5r0Q+Wi8Xa470nATyduELJKW4=";

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
