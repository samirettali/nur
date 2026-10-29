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
  version = "0.166.0";

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
        hash = "sha256-xIgkRi/FdoHq+wkl2XsRtYkBBHVhOQT1cLQv6lPiQNU=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-aarch64-unknown-linux-musl.tar.gz";
        hash = "sha256-lOtwdgXsJkay4Ft+33xOezzPArFiN8NK6b64z7f4EKk=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-x86_64-apple-darwin.tar.gz";
        hash = "sha256-2ww4cTw2GZsS58jRYpOGw1pM6PmeHJznLxclp032e1c=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-oL9XLS+T8FbGcSpto0jpYHjchPOIX9e+Z4B+84nLOXg=";
      };
    };

    codeModeHostSources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-aarch64-apple-darwin.tar.gz";
        hash = "sha256-er1Q/l8DNJWntpPEX7gtxXCToY8cS6PoBDV33kbFx8U=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-aarch64-unknown-linux-musl.tar.gz";
        hash = "sha256-rJjR+HjjU6FsunEf1Hv+8vbIFBCb3YGe4ra21qGXAec=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-x86_64-apple-darwin.tar.gz";
        hash = "sha256-s1x3XV5fjWDQXg3nFU5bu/MgttDiijI31CzIp0LMr2U=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-dYgzT9R7xAA9lwtw39TR5FeEkbHpuqcpdqTC1+l1kNo=";
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
