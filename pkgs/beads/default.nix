{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  go,
}:
let
  go_1_25_8 = go.overrideAttrs (_oldAttrs: rec {
    version = "1.25.8";
    src = fetchurl {
      url = "https://dl.google.com/go/go${version}.src.tar.gz";
      hash = "sha256-6YjUokRqx/4/baoImljpk2pSo4E1Wt7ByJgyMKjWxZ4=";
    };
  });
in
(buildGoModule.override { go = go_1_25_8; }) rec {
  pname = "beads";
  version = "0.60.0";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v${version}";
    hash = "sha256-z3EDtaBHB3ltPRT7vuBFURD7UwgAJBXAPozRnkjejeU=";
  };

  vendorHash = "sha256-1BJsEPP5SYZFGCWHLn532IUKlzcGDg5nhrqGWylEHgY=";

  doCheck = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "A memory upgrade for your coding agent";
    homepage = "https://github.com/steveyegge/beads";
    changelog = "https://github.com/steveyegge/beads/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "bd";
  };
}
