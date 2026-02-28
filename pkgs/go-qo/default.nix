{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go_1_26,
}:
(buildGoModule.override {go = go_1_26;}) rec {
  pname = "go-qo";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "kiki-ki";
    repo = "go-qo";
    rev = "v${version}";
    hash = "sha256-cXE0ZfMNp05MpXX97iAYbLp+uQ1qM3Qiof6sIG0fAAI=";
  };

  vendorHash = "sha256-P/QKOamka6ENyvSI0N5YOwdlKWVN7iyxuwR3g6hAeGs=";

  meta = {
    description = "A minimalist TUI for querying JSON, CSV using SQL";
    homepage = "https://github.com/kiki-ki/go-qo";
    changelog = "https://github.com/kiki-ki/go-qo/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "qo";
  };
}
