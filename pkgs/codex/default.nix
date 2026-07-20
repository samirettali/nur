{
  lib,
  stdenvNoCC,
  fetchurl,
  gnutar,
  gzip,
  makeWrapper,
  bubblewrap,
}:
let
  linuxRuntimePath = lib.makeBinPath (lib.optionals stdenvNoCC.isLinux [bubblewrap]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codex";
  version = "0.144.6";

  platform =
    finalAttrs.passthru.platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;
  nativeBuildInputs = [
    gnutar
    gzip
    makeWrapper
  ];

  unpackPhase = ''
    unpackFile $src
  '';

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ./codex-${finalAttrs.platform} $out/bin/codex-raw
    makeWrapper "$out/bin/codex-raw" "$out/bin/codex" \
      --run 'export CODEX_EXECUTABLE_PATH="$HOME/.local/bin/codex"' \
      --set DISABLE_AUTOUPDATER 1 \
      ${lib.optionalString stdenvNoCC.isLinux ''--prefix PATH : "${linuxRuntimePath}"''}

    runHook postInstall
  '';

  passthru = {
    platformMap = {
      "aarch64-darwin" = "aarch64-apple-darwin";
      "aarch64-linux" = "aarch64-unknown-linux-musl";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "x86_64-linux" = "x86_64-unknown-linux-musl";
    };

    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-aarch64-apple-darwin.tar.gz";
        hash = "sha256-AjWQ+Ci8lQesYRMu415008XTP7W6Phyk/C4BOi9xo9c=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-aarch64-unknown-linux-musl.tar.gz";
        hash = "sha256-jt2uXmwAnf+bpRrhv+O92f9MHMyTpIzGhg2xzZ/fEb4=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-x86_64-apple-darwin.tar.gz";
        hash = "sha256-djyBpWuiSk9sL9JW7X7hd1yuzNIlN9KIh96PaGSsWUc=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-ap3vUaCtjOpmhNjrO/AzyJ8z47xc/kkvGh4KcYRRocY=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${finalAttrs.version}";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    mainProgram = "codex";
  };
})
