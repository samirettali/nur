{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go_1_26,
}:
(buildGoModule.override {go = go_1_26;}) rec {
  pname = "go-qo";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "kiki-ki";
    repo = "go-qo";
    rev = "v${version}";
    hash = "sha256-/P/ftmiwSP0ovAwBHIPkXVueL9lvxX9lCC+0S9ihJv4=";
  };

  vendorHash = "sha256-rA33FOp/p7GOZpHBzhkkRkMPFZNqKsmFUUFIkT7NCaU=";

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
