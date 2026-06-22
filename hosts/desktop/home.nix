{ config, pkgs, ... }:
{
  imports = [
    ../../modules/hyprland.nix
    ../../modules/quickshell.nix
    ../../modules/mail.nix
    ../../modules/browser.nix
  ];

  wayland.windowManager.hyprland.settings.monitor = pkgs.lib.mkForce [
    { output = "desc:Apple Computer Inc StudioDisplay"; mode = "5120x2880@60"; position = "auto"; scale = 2; }
    { output = ""; mode = "preferred"; position = "auto"; scale = 1; }
  ];

  wayland.windowManager.hyprland.settings.env = [
    { _args = [ "XDG_DATA_DIRS" "${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share" ]; }
    { _args = [ "LIBVA_DRIVER_NAME" "nvidia" ]; }
    { _args = [ "GBM_BACKEND" "nvidia-drm" ]; }
    { _args = [ "__GLX_VENDOR_LIBRARY_NAME" "nvidia" ]; }
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    hl.config({ cursor = { no_hardware_cursors = true } })
  '';

  home.username = "andrewkim";
  home.homeDirectory = "/home/andrewkim";


  home.packages = with pkgs; [
    hyprlock
    pulsemixer
    steam
  ];

  home.file.".local/bin/steam-qs" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec >>/tmp/steam-qs.log 2>&1
      echo "=== $(date) ==="
      echo "HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE"
      echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
      echo "DISPLAY=$DISPLAY"
      exec ${config.home.homeDirectory}/.nix-profile/bin/steam --no-cef-sandbox &
      STEAM_PID=$!
      sleep 5
      echo "=== hyprctl clients after 5s ==="
      hyprctl clients 2>&1 | grep -A5 -i steam || echo "no steam window found"
      echo "=== steam proc ==="
      pgrep -a steam 2>&1 || echo "no steam procs"
      wait $STEAM_PID
    '';
  };

  xdg.desktopEntries.steam = {
    name = "Steam";
    exec = "${config.home.homeDirectory}/.local/bin/steam-qs";
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
