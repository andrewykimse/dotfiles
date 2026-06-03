{ pkgs, dracula-wallpaper, ... }:
let
  screenshot-area = pkgs.writeShellScript "screenshot-area" ''
    grim -g "$(slurp)" - | wl-copy
  '';
  screenshot-full = pkgs.writeShellScript "screenshot-full" ''
    grim - | wl-copy
  '';
  wallpaper-dir = "${dracula-wallpaper}";
  random-wallpaper = pkgs.writeShellScript "random-wallpaper" ''
    export PATH="${pkgs.lib.makeBinPath [ pkgs.findutils pkgs.coreutils pkgs.hyprland ]}:$PATH"
    wallpaper=$(find ${wallpaper-dir} -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
    hyprctl hyprpaper preload "$wallpaper"
    hyprctl hyprpaper wallpaper ", $wallpaper"
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
    configType = "hyprlang";
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$lock" = "hyprlock";

      monitor = [
        "eDP-1, preferred, auto, 2"
        ", preferred, auto, 1"
      ];

      bindl = [
        ", switch:on:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, disable\""
        ", switch:off:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, preferred, auto, 2\""
      ];

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_DATA_DIRS"
        "systemctl --user restart xdg-desktop-portal"
        "hyprpaper"
        "sleep 1 && ${random-wallpaper}"
        "hypridle"
        "wl-paste --watch cliphist store"
        "systemctl --user start hyprpolkitagent"
      ];

      animations = {
        enabled = true;
        bezier = "snap, 0.05, 0.9, 0.1, 1.0";
        animation = [
          "windows, 1, 2, snap"
          "windowsOut, 1, 2, snap, popin 80%"
          "windowsMove, 1, 2, snap"
          "workspaces, 1, 2, snap"
          "fade, 1, 2, default"
          "border, 1, 8, default"
        ];
      };

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
        "$mod, Space, exec, noctalia-shell ipc call launcher toggle"
        "$mod, V, togglefloating,"
        "$mod, F, fullscreen,"

        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        "$mod CTRL, h, movewindow, l"
        "$mod CTRL, l, movewindow, r"
        "$mod CTRL, k, movewindow, u"
        "$mod CTRL, j, movewindow, d"

        "$mod, Escape, exec, $lock"
        "$mod SHIFT, V, exec, noctalia-shell ipc call launcher clipboard"

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

      binde = [
        "$mod SHIFT, h, resizeactive, -30 0"
        "$mod SHIFT, l, resizeactive, 30 0"
        "$mod SHIFT, k, resizeactive, 0 -30"
        "$mod SHIFT, j, resizeactive, 0 30"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp,  exec, brightnessctl s 5%+"
        ", XF86MonBrightnessDown,exec, brightnessctl s 5%-"
      ];
    };
  };

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

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = false
  '';

  xdg.configFile."hypr/hyprlock.conf".text = ''
    background {
      monitor =
      color = rgba(40, 42, 54, 1.0)
    }

    input-field {
      monitor =
      size = 300, 50
      outline_thickness = 2
      outer_color = rgb(bd93f9)
      inner_color = rgb(68, 71, 90)
      font_color = rgb(f8f8f2)
      fade_on_empty = true
      placeholder_text = <i>Password...</i>
      halign = center
      valign = center
    }
  '';

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      lock_cmd = hyprlock
      before_sleep_cmd = loginctl lock-session
    }

    listener {
      timeout = 300
      on-timeout = hyprlock
    }

    listener {
      timeout = 600
      on-timeout = hyprctl dispatch dpms off
      on-resume = hyprctl dispatch dpms on
    }
  '';
}
