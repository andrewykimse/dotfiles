{ pkgs, hyprland-config, ... }:
let
  screenshot-area = pkgs.writeShellScript "screenshot-area" ''
    grim -g "$(slurp)" - | wl-copy
  '';
  screenshot-full = pkgs.writeShellScript "screenshot-full" ''
    grim - | wl-copy
  '';
in
{
  home.packages = with pkgs; [
    hyprpaper
    hypridle
    hyprpolkitagent
    xdg-desktop-portal-gtk
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    pavucontrol
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    settings = {
      mod      = { _var = "SUPER"; };
      terminal = { _var = "ghostty"; };
      lock     = { _var = "hyprlock"; };
      monitor  = [
        { output = "eDP-1"; mode = "preferred"; position = "auto"; scale = 2; }
        { output = "";      mode = "preferred"; position = "auto"; scale = 1; }
      ];
    };
    extraConfig = builtins.readFile "${hyprland-config}/hypr/hyprland.lua";
  };

  xdg.configFile."hypr/hyprpaper.conf".source = "${hyprland-config}/hypr/hyprpaper.conf";
  xdg.configFile."hypr/hyprlock.conf".source  = "${hyprland-config}/hypr/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source  = "${hyprland-config}/hypr/hypridle.conf";

  xdg.desktopEntries = {
    shutdown = {
      name = "Shutdown";
      exec = "systemctl poweroff";
      icon = "system-shutdown";
      categories = [ "System" ];
    };
    reboot = {
      name = "Reboot";
      exec = "systemctl reboot";
      icon = "system-reboot";
      categories = [ "System" ];
    };
    suspend = {
      name = "Suspend";
      exec = "systemctl suspend";
      icon = "system-suspend";
      categories = [ "System" ];
    };
    lock = {
      name = "Lock Screen";
      exec = "hyprlock";
      icon = "system-lock-screen";
      categories = [ "System" ];
    };
    logout = {
      name = "Logout";
      exec = "hyprctl dispatch exit";
      icon = "system-log-out";
      categories = [ "System" ];
    };
    restart-wifi = {
      name = "Restart WiFi";
      exec = "systemctl restart NetworkManager";
      icon = "network-wireless";
      categories = [ "System" ];
    };
    toggle-bluetooth = {
      name = "Toggle Bluetooth";
      exec = "rfkill toggle bluetooth";
      icon = "bluetooth";
      categories = [ "System" ];
    };
    screenshot-area = {
      name = "Screenshot (Area)";
      exec = "${screenshot-area}";
      icon = "accessories-screenshot";
      categories = [ "Utility" ];
    };
    screenshot-full = {
      name = "Screenshot (Full)";
      exec = "${screenshot-full}";
      icon = "accessories-screenshot";
      categories = [ "Utility" ];
    };
  };
}
