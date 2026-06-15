{ ... }:
{
  imports = [
    ../../modules/shell.nix
    ../../modules/git.nix
    ../../modules/terminal.nix
    ../../modules/dev.nix
  ];

  home.username = "andrewkim";
  home.homeDirectory = "/home/andrewkim";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
