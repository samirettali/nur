{
  lib,
  rustPlatform,
  fetchFromGitHub,
  direnv,
}:
rustPlatform.buildRustPackage rec {
  pname = "quickenv";
  version = "0.4.4";

  src = fetchFromGitHub {
    owner = "untitaker";
    repo = "quickenv";
    rev = version;
    hash = "sha256-APIsYdT8J1oiYcGFEhIzMa9e7c3GOcyiZx1UTVRDrgU=";
  };

  cargoHash = "sha256-/o8WYFAr8J2PDiGHOCnl3u+QXi8es88CKCFLkfFE+fI=";

  nativeCheckInputs = [ direnv ];

  preCheck = ''
    # Tests expect the binary at target/debug/quickenv, but Nix builds in release mode
    mkdir -p target/debug
    cp target/*/release/quickenv target/debug/quickenv
  '';

  meta = {
    description = "An unintrusive environment manager";
    homepage = "https://github.com/untitaker/quickenv";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "quickenv";
  };
}
