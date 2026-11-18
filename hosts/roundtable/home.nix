{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/common.nix
  ];

  home.username = "andrewkim";
  home.homeDirectory = "/home/andrewkim";
  home.stateVersion = lib.mkForce "25.11";

  programs.home-manager.enable = true;

  home.packages = [ (import ../../packages/opencode2 { inherit pkgs; }) ];
}
