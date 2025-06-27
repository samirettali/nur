{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}: let
  opencode-pkg = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "opencode";
    version = "0.1.146";

    src =
      finalAttrs.passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

    strictDeps = true;
    nativeBuildInputs = [unzip];

    unpackPhase = ''
      unpackFile $src
    '';

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      install -Dm 755 ./opencode $out/bin/opencode

      runHook postInstall
    '';

    passthru = {
      sources = {
        "aarch64-darwin" = fetchurl {
          url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-darwin-arm64.zip";
          hash = "sha256-YGgb5XOvpo6dYrf8iTJs0eVPrxuzwuqR27KiycHh+bc=";
        };
        "aarch64-linux" = fetchurl {
          url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-linux-arm64.zip";
          hash = "sha256-DgYDsZ3+2QYxKQE7Iu1ybs1MILr0wVC2oMHy9GKJML4=";
        };
        "x86_64-darwin" = fetchurl {
          url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-darwin-x64.zip";
          hash = "sha256-DPROip/v1xbfR2KGqs2qIzixuJoFEZfe46bJwwkxR6g=";
        };
        "x86_64-linux" = fetchurl {
          url = "https://github.com/sst/opencode/releases/download/v${finalAttrs.version}/opencode-linux-x64.zip";
          hash = "sha256-jM/DZ9T7drIq933mgI40JSA0AYJMYsjybw/CTlOuS7o=";
        };
      };

      updateScript = ./update.sh;
    };

    meta = {
      description = "The AI coding agent built for the terminal";
      longDescription = ''
        OpenCode is a terminal-based agent that can build anything.
        It combines a TypeScript/JavaScript core with a Go-based TUI
        to provide an interactive AI coding experience.
      '';
      homepage = "https://github.com/sst/opencode";
      license = lib.licenses.mit;
      platforms = builtins.attrNames finalAttrs.passthru.sources;
      mainProgram = "opencode";
    };
  });
in {
  opencode = opencode-pkg;

  homeManagerModules.opencode = {
    config,
    pkgs,
    ...
  }: {
    options.programs.opencode = {
      enable = lib.mkEnableOption "opencode, the AI coding agent";

      package = lib.mkOption {
        type = lib.types.package;
        default = opencode-pkg;
        defaultText = lib.literalExpression "pkgs.opencode";
        description = "The opencode package to install.";
      };

      settings = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = {};
        description = ''
          Configuration for opencode.
          This will be written to <literal>~/.opencode/config.json</literal>.
        '';
        example = lib.literalExpression ''
          {
            model = "openai/gpt-4-turbo-preview";
          }
        '';
      };
    };

    config = lib.mkIf config.programs.opencode.enable {
      home.packages = [config.programs.opencode.package];

      home.file.".config/opencode/config.json" = {
        source = pkgs.formats.json.generate "opencode-config.json" config.programs.opencode.settings;
      };
    };
  };
}
