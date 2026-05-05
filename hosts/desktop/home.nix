{ pkgs, ... }:
{
  imports = [ ../../modules/hyprland.nix ];

  home.username = "andrewkim";
  home.homeDirectory = "/home/andrewkim";

  # NixOS desktop-specific packages
  home.packages = with pkgs; [
    # add linux-only tools here
    steam
  ];

  programs.ghostty = {
    enable = true;
    settings = {
      font-size = 13;
      window-padding-x = 8;
      window-padding-y = 8;
      window-decoration = false;
      copy-on-select = true;
      scrollback-limit = 10000;
      theme = "dracula";
    };
  };
}
