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

  opencode = pkgs.callPackage ./pkgs/opencode {};
  gemini-cli = pkgs.callPackage ./pkgs/gemini-cli {};
  wgsl-analyzer = pkgs.callPackage ./pkgs/wgsl-analyzer {};
  zesh = pkgs.callPackage ./pkgs/zesh {};
  git-sync = pkgs.callPackage ./pkgs/git-sync {};
  csharp-ls = pkgs.callPackage ./pkgs/csharp-ls {};
}
