{ pkgs, ... }:
{
  home.username = "akim7";
  home.homeDirectory = "/home/akim7";

  programs.ghostty.enable = pkgs.lib.mkForce false;

  xdg.configFile."ghostty/config".text = ''
    theme = Dracula
    command = ${pkgs.zsh}/bin/zsh
  '';


  home.packages = [
    pkgs.awscli2
    pkgs.cachix
  ];
}
