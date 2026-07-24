{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${version}";
    hash = "sha256-ITN+7CAeyn5/iUcNYWrREREnngpzjBZF9cWGX5UV+3k=";
  };

  cargoHash = "sha256-qN34EIfS6etz4E5PO17QoUp9YrfiqVcYgz+cs+B1c9w=";

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
