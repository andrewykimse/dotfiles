{ ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./terminal.nix
    ./dev.nix
    ./browser.nix
  ];

  # home.username and home.homeDirectory are set per-host

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
