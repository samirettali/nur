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
  version = "0.162.0";

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
        hash = "sha256-mOlBOhvRZ65XNyOTn/F45tRPG7IdXNqWDb6y+mX0kQQ=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-aarch64-unknown-linux-musl.tar.gz";
        hash = "sha256-FRYqm1nt+OUSsnQU7At9si5kJKEmKw7uhmZkPg0pXC8=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-x86_64-apple-darwin.tar.gz";
        hash = "sha256-PK9khATLXSkX9uiPCt2zUzWE+LBaHdWDXddvHEPusms=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-ja9n9iYRYapZOdjUKlFgMtdgQGIWd5185gQPJCFA/3M=";
      };
    };

    codeModeHostSources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
        hash = "sha256-lFXBf6m6bon47CTr/TQZgl4sZRxW+L2N9xQUEebezcI=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz";
        hash = "sha256-GNmbBV0u9KKvUfEUSRm9iiCPT3ms44m3d1NB1pA89+k=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-x86_64-apple-darwin.tar.gz";
        hash = "sha256-p+IG4xd3RUZ6x88tQ7j/kxNN/JVcHLRlKWAOGjQhM0k=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-3ui/PfY3xo4Ulbko1kO3bUrUT5Tk8O15/oSC+nniPZc=";
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
