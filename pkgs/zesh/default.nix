{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "zesh";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "roberte777";
    repo = "zesh";
    rev = "zesh-v${version}";
    hash = "sha256-10zKOsNEcHb/bNcGC/TJLA738G0cKeMg1vt+PZpiEUI=";
  };

  cargoHash = "sha256-N39JD7qeLzro4+6wSP14uAjH8D7kv6sGuhLomcVw600=";

  meta = {
    description = "";
    homepage = "https://github.com/roberte777/zesh";
    changelog = "https://github.com/roberte777/zesh/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "zesh";
  };
}
