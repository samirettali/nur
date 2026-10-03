{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go_1_26,
}:
(buildGoModule.override {go = go_1_26;}) rec {
  pname = "go-qo";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "kiki-ki";
    repo = "go-qo";
    rev = "v${version}";
    hash = "sha256-IQaMpeP9DkNV+sXiD2EkakJwc47tOgAkoEaXF2/ysh8=";
  };

  vendorHash = "sha256-iyCQv5f2MuTA/6nMAgwhetYt3Pef9umCMzNJ1r9puFI=";

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
