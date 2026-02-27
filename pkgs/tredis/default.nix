{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "tredis";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "huseyinbabal";
    repo = "tredis";
    rev = "v${version}";
    hash = "sha256-AKyQQ7W0LOsxGUtGxnOAN90SaGAQC4ReYjtAXN9+lYQ=";
  };

  cargoHash = "sha256-5EMxHYwEj4lGFMK37HfOeJ5ombZ2KyTor4qSvom30P0=";

  meta = {
    description = "A modern TUI for managing Redis servers";
    homepage = "https://github.com/huseyinbabal/tredis";
    changelog = "https://github.com/huseyinbabal/tredis/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "tredis";
  };
}
