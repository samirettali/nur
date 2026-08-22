{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  makeBinaryWrapper,
  glibc,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "claude-code";
  version = "2.1.240";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;
  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [makeBinaryWrapper];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  # The release binary is a bun standalone executable: bun locates its embedded
  # bundle through a trailer at the end of the file. patchelf cannot rewrite the
  # interpreter in place and appends to the file, which moves that trailer away
  # from the end; bun then finds no bundle and prints its own help. So keep the
  # binary byte for byte and call the loader explicitly instead.
  installPhase =
    ''
      runHook preInstall

    ''
    + (
      if stdenvNoCC.hostPlatform.isLinux
      then ''
        install -Dm 755 ./claude $out/libexec/claude-code/claude

        makeWrapper ${stdenv.cc.bintools.dynamicLinker} $out/bin/claude \
          --add-flags --library-path \
          --add-flags ${lib.makeLibraryPath [glibc]} \
          --add-flags --argv0 \
          --add-flags claude \
          --add-flags $out/libexec/claude-code/claude
      ''
      else ''
        install -Dm 755 ./claude $out/bin/claude
      ''
    )
    + ''

      runHook postInstall
    '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-darwin-arm64.tar.gz";
        hash = "sha256-U+qGAtWV1NIEk0NmJUW24in1EVJaO0zG/mIsHfQ1Wyo=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-linux-arm64.tar.gz";
        hash = "sha256-0srHVfAC73BrOq3DMVKsqQcSwm251GXH8rz1ODDuls4=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-darwin-x64.tar.gz";
        hash = "sha256-qHGUKNtk+4h2IllzOh5aXw5xIMBi3MAk/I5iclfDNjc=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-linux-x64.tar.gz";
        hash = "sha256-kfnZl61nYAL36svDOhV5dy1XWDBB+S5Q9lbmqDYLzrw=";
      };
    };

    updateScript = ./update.sh;
  };

  meta = {
    description = "Agentic coding tool that lives in your terminal";
    longDescription = ''
      Claude Code is Anthropic's agentic coding tool. It understands your
      codebase, edits files, runs terminal commands and handles entire
      workflows from the terminal.

      This package installs the official native build. The binary lives in the
      read-only Nix store, so the built-in auto-updater cannot replace it: set
      DISABLE_AUTOUPDATER=1 and bump the package instead.
    '';
    homepage = "https://github.com/anthropics/claude-code";
    changelog = "https://github.com/anthropics/claude-code/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.unfree;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    mainProgram = "claude";
  };
})
