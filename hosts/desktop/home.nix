{ config, pkgs, nixos-millennium, ... }:
{
  imports = [
    ../../modules/hyprland.nix
    ../../modules/noctalia.nix
    ../../modules/mail.nix
  ];

  nixpkgs.overlays = [ nixos-millennium.overlays.default ];

  wayland.windowManager.hyprland.settings.env = [
    "XDG_DATA_DIRS,${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share"
    "LIBVA_DRIVER_NAME,nvidia"
    "GBM_BACKEND,nvidia-drm"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
  ];

  wayland.windowManager.hyprland.settings.cursor = {
    no_hardware_cursors = true;
  };

  wayland.windowManager.hyprland.settings.monitor = pkgs.lib.mkForce [
    "desc:Apple Computer Inc StudioDisplay, 5120x2880@60, auto, 2"
    ", preferred, auto, 1"
  ];

  home.username = "andrewkim";
  home.homeDirectory = "/home/andrewkim";


  home.packages = with pkgs; [
    hyprlock
    millennium-steam
  ];

  programs.steam = {
    theme = pkgs.millenniumThemes.space;
    millenniumConfig.themes.conditions."space-theme-steam" = {
      "--st-background"   = "40, 42, 54";
      "--st-accent-1"     = "189, 147, 249";
      "--st-accent-2"     = "255, 121, 198";
      "--st-color-1"      = "30, 31, 41";
      "--st-color-2"      = "40, 42, 54";
      "--st-color-3"      = "68, 71, 90";
      "--st-color-4"      = "80, 84, 108";
      "--st-color-5"      = "98, 114, 164";
      "--st-blue"         = "139, 233, 253";
      "--st-blue-hover"   = "169, 241, 255";
      "--st-green"        = "80, 250, 123";
      "--st-green-hover"  = "120, 251, 155";
      "--st-red"          = "255, 85, 85";
      "--st-red-hover"    = "255, 128, 128";
      "--st-yellow"       = "241, 250, 140";
      "--st-yellow-hover" = "245, 251, 176";
    };
  };

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
      theme = "Dracula";
    };
  };
}
