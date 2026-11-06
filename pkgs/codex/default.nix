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
  linuxRuntimePath = lib.makeBinPath (lib.optionals stdenvNoCC.hostPlatform.isLinux [bubblewrap]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codex";
  version = "0.167.0";

  platform =
    finalAttrs.passthru.platformMap.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  codeModeHostSrc =
    finalAttrs.passthru.codeModeHostSources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;
  nativeBuildInputs = [
    gnutar
    gzip
    makeWrapper
  ];

  unpackPhase = ''
    unpackFile $src
    unpackFile $codeModeHostSrc
  '';

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ./codex-${finalAttrs.platform} $out/bin/codex-raw
    install -Dm755 ./codex-code-mode-host-${finalAttrs.platform} $out/bin/codex-code-mode-host
    makeWrapper "$out/bin/codex-raw" "$out/bin/codex" \
      --run 'export CODEX_EXECUTABLE_PATH="$HOME/.local/bin/codex"' \
      --set DISABLE_AUTOUPDATER 1 \
      ${lib.optionalString stdenvNoCC.hostPlatform.isLinux ''--prefix PATH : "${linuxRuntimePath}"''}

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
        hash = "sha256-SyKiqXG+J5HD4x+RLz53qI69ZKZYEqconMumXdZCX+k=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-aarch64-unknown-linux-musl.tar.gz";
        hash = "sha256-hDSJrLTUsQeXRcNrA8WWO4h7gxVa8gj9U1hOM+6OsoE=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-x86_64-apple-darwin.tar.gz";
        hash = "sha256-2OtKhloLFzGc3hA0dSPlurCXjQFyWzn0pjn0CQXgEiE=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-nWSDYQbVs3TpDuRFTH683nynEGVYvX5Bo0ufJuvaJRo=";
      };
    };

    codeModeHostSources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
        hash = "sha256-h2o+JjNI7w7a6uXPW8UqXBIRQc79FRV6sO7KMF8+tWM=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz";
        hash = "sha256-bpmUj6IMqBagHyIqVq+iYbMh4Ay+1hHXa7ksdl/RHsY=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-x86_64-apple-darwin.tar.gz";
        hash = "sha256-YS0Nwscxb78F7pInlvTXQKKFt2pV1MeOG5RrpiG9zJE=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-tQdNXdZGQ7LAc5J+SUpYjv8xwfWifxLB4sRfmmzwfdQ=";
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
