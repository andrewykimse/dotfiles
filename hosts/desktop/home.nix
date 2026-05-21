{ config, pkgs, ... }:
{
  imports = [ ../../modules/hyprland.nix ];

  wayland.windowManager.hyprland.settings.env = [
    "XDG_DATA_DIRS,${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share"
  ];

  home.username = "andrewkim";
  home.homeDirectory = "/home/andrewkim";


  home.packages = with pkgs; [
    hyprlock
    steam
  ];

  xdg.desktopEntries.steam = {
    name = "Steam";
    exec = "steam --no-cef-sandbox %U";
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [ "Network" "FileTransfer" "Game" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
  };

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
