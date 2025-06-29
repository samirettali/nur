{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.programs.opencode;
  opencode = pkgs.callPackage ../pkgs/opencode {};
in {
  options.programs.opencode = {
    enable = mkEnableOption "opencode cli";

    package = mkOption {
      type = types.package;
      default = opencode;
      description = "The opencode package to use";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Configuration settings for OpenCode";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];
    xdg.configFile."opencode/config.json".text = builtins.toJSON cfg.settings;
  };
}
