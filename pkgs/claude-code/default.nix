{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "claude-code";
  version = "2.1.310";

  src =
    finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  # The release binary is a bun standalone executable: bun locates its embedded
  # bundle through a trailer at the end of the file. patchelf cannot rewrite the
  # interpreter in place and appends to the file, which moves that trailer away
  # from the end; bun then finds no bundle and crashes. So the binary is
  # installed byte for byte and runs through the host's own FHS loader.
  #
  # Calling the store loader explicitly instead — ld-linux.so --library-path …
  # ./claude — is what this package used to do, and it is worse than an impure
  # dependency: when a program is started that way, /proc/self/exe names the
  # loader rather than the program. Claude reads its own path from there and
  # re-executes itself for every subprocess it spawns — remote-control sessions,
  # the multicall grep and find helpers it injects into the shell — so each one
  # ran ld-linux.so with Claude's flags and died on `unrecognized option`.
  #
  # A NixOS host therefore needs programs.nix-ld.enable to provide the loader at
  # its FHS path; every other Linux distribution already has it.
  installPhase = ''
    runHook preInstall

    install -Dm 755 ./claude $out/bin/claude

    runHook postInstall
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-darwin-arm64.tar.gz";
        hash = "sha256-z0fTAAT/JuXP7WAEopypTgWtU9b4kO4b6LtYLozipbU=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-linux-arm64.tar.gz";
        hash = "sha256-l6tFpC/bFB3DfTsSlzY469j9pZFj7KUbAqou3tBjCHQ=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-darwin-x64.tar.gz";
        hash = "sha256-TGL0k0H32QK7khhtZ+7irb8BT6upq2F3Kd5S17cZ4cQ=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/anthropics/claude-code/releases/download/v${finalAttrs.version}/claude-linux-x64.tar.gz";
        hash = "sha256-W+qeE6wH6mgEwk5iY+x+Wz0T+B0/aByS+XhMU0Ql+uE=";
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
