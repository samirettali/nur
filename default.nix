# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage
{pkgs ? import <nixpkgs> {}}: {
  # The `lib`, `modules`, and `overlays` names are special
  lib = import ./lib {inherit pkgs;}; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  # cursor = pkgs.callPackage ./pkgs/cursor {
  #   vscode-generic = import "${pkgs.path}/pkgs/applications/editors/vscode/generic.nix";
  # };

  codex = pkgs.callPackage ./pkgs/codex {};
  grok-cli = pkgs.callPackage ./pkgs/grok-cli {};
  cmux = pkgs.callPackage ./pkgs/cmux {};
  opencode = pkgs.callPackage ./pkgs/opencode {};
  zesh = pkgs.callPackage ./pkgs/zesh {};
  git-sync = pkgs.callPackage ./pkgs/git-sync {};
  tredis = pkgs.callPackage ./pkgs/tredis {};
  go-qo = pkgs.callPackage ./pkgs/go-qo {};
  hunk = pkgs.callPackage ./pkgs/hunk {};
  spotctl = pkgs.callPackage ./pkgs/spotctl {};
  mole = pkgs.callPackage ./pkgs/mole {};
  rift = pkgs.callPackage ./pkgs/rift {};
  ghostty = pkgs.callPackage ./pkgs/ghostty {};
  quartz = pkgs.callPackage ./pkgs/quartz {};
  pi-coding-agent = pkgs.callPackage ./pkgs/pi-coding-agent {};
  pi-mcp-adapter = pkgs.callPackage ./pkgs/pi-mcp-adapter {};
  pi-provider-kimi-code = pkgs.callPackage ./pkgs/pi-provider-kimi-code {};
  tailscale-gui = pkgs.callPackage ./pkgs/tailscale-gui {};
  sol = pkgs.callPackage ./pkgs/sol {};
  eqmac = pkgs.callPackage ./pkgs/eqmac {};
  lathe = pkgs.callPackage ./pkgs/lathe {};
}
