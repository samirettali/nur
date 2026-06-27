{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go_1_26,
}:
(buildGoModule.override {go = go_1_26;}) rec {
  pname = "go-qo";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "kiki-ki";
    repo = "go-qo";
    rev = "v${version}";
    hash = "sha256-zCjgGf5/aCGJ2svIrSS8H6zdwjDGFsiLXBL9B2N1qnU=";
  };

  vendorHash = "sha256-Gp4kgmZNE2Juge1zN1UyfGNggJv9yRwdBOyygNAgsMI=";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "A minimalist TUI for querying JSON, CSV using SQL";
    homepage = "https://github.com/kiki-ki/go-qo";
    changelog = "https://github.com/kiki-ki/go-qo/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "qo";
  };
}
