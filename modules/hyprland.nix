{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hyprpaper
    hyprlock
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$menu" = "wofi --show drun";

      monitor = [ ",preferred,auto,2" ];

      exec-once = [
        "waybar"
        "mako"
        "hyprpaper"
      ];

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(bd93f9ee) rgba(ff79c6ee) 45deg";
        "col.inactive_border" = "rgba(44475aaa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 6;
        blur.enabled = true;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive,"
        "$mod SHIFT, E, exit,"
        "$mod, R, exec, $menu"
        "$mod, V, togglefloating,"
        "$mod, F, fullscreen,"

        "$mod, left,  movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up,    movefocus, u"
        "$mod, down,  movefocus, d"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp,  exec, brightnessctl s 5%+"
        ", XF86MonBrightnessDown,exec, brightnessctl s 5%-"
      ];
    };
  };

  programs.waybar = {
    enable = true;
    systemd.enable = false;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 28;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];
      clock.format = "{:%a %b %d  %H:%M}";
      battery = {
        format = "{capacity}% {icon}";
        format-icons = [ "" "" "" "" "" ];
      };
    };
    style = ''
      * { font-family: "JetBrainsMono Nerd Font", monospace; font-size: 12px; }
      window#waybar { background: rgba(40, 42, 54, 0.85); color: #f8f8f2; }
      #workspaces button.active { background: #bd93f9; color: #282a36; }
    '';
  };

  programs.wofi.enable = true;

  services.mako = {
    enable = true;
    settings = {
      background-color = "#282a36";
      text-color = "#f8f8f2";
      border-color = "#bd93f9";
      border-radius = 6;
      default-timeout = 5000;
    };
  };
}
