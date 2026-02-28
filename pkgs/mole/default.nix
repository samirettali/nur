{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mole";
  version = "1.28.0";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "mole";
    rev = "V${version}";
    hash = "sha256-K2+4p1t8MTuAYldPLL2W5VUOff+NNy5hqfrkv1YKYxI=";
  };

  vendorHash = "sha256-OKM5rmbLxqh5Khw5BlR/gPJlwmQhklGdZst92aUTZhM=";

  # Tests interact with macOS Trash which is unavailable in the Nix sandbox
  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/mole/bin

    cp ${src}/mole $out/share/mole/mole
    cp -r ${src}/lib $out/share/mole/lib
    cp ${src}/bin/*.sh $out/share/mole/bin/

    # buildGoModule produces 'analyze' and 'status'; scripts expect 'analyze-go' and 'status-go'
    mv $out/bin/analyze $out/share/mole/bin/analyze-go
    mv $out/bin/status $out/share/mole/bin/status-go

    chmod +x $out/share/mole/mole $out/share/mole/bin/*.sh

    # Real wrapper scripts (not symlinks): BASH_SOURCE[0] must resolve to share/mole/
    # so that the mole script finds lib/ and bin/ relative to itself
    printf '#!/bin/bash\nexec %s/share/mole/mole "$@"\n' "$out" > $out/bin/mole
    printf '#!/bin/bash\nexec %s/share/mole/mole "$@"\n' "$out" > $out/bin/mo
    chmod +x $out/bin/mole $out/bin/mo
  '';

  meta = {
    description = "A macOS utility for cleaning, optimization, and system monitoring";
    homepage = "https://github.com/tw93/mole";
    changelog = "https://github.com/tw93/mole/releases/tag/V${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "mo";
    platforms = lib.platforms.darwin;
  };
}
