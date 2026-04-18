{
  lib,
  stdenvNoCC,
  fetchurl,
  xar,
  cpio,
  pbzx,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tailscale-gui";
  version = "1.96.5";

  src = fetchurl {
    url = "https://pkgs.tailscale.com/stable/Tailscale-${finalAttrs.version}-macos.pkg";
    hash = "sha256-eqwNX5uBGOiy1z91eMMkE6892ot+eXlM5/6jHm9uF8g=";
  };

  strictDeps = true;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    xar
    cpio
    pbzx
  ];

  installPhase = ''
    runHook preInstall

    xar -xf $src
    cd Distribution.pkg
    pbzx -n Payload | cpio -i

    mkdir -p $out/Applications/Tailscale.app
    cp -R Contents $out/Applications/Tailscale.app/

    mkdir -p $out/bin
    ln -s "$out/Applications/Tailscale.app/Contents/MacOS/Tailscale" "$out/bin/tailscale"

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Tailscale GUI client for macOS";
    homepage = "https://tailscale.com";
    changelog = "https://tailscale.com/changelog#client";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [];
    platforms = lib.platforms.darwin;
    mainProgram = "tailscale";
  };
})
