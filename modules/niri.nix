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
    export PATH="${pkgs.lib.makeBinPath [ pkgs.findutils pkgs.coreutils pkgs.swaybg ]}:$PATH"
    wallpaper=$(find ${wallpaper-dir} -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)
    pkill swaybg || true
    swaybg -i "$wallpaper" -m fill &
  '';
in
{
  home.packages = with pkgs; [
    niri
    xwayland-satellite
    swaybg
    swayidle
    swaylock
    xdg-desktop-portal-gnome
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    pavucontrol
  ];

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }

        touchpad {
            natural-scroll
            tap
        }

        mouse {
            accel-profile "flat"
        }

        focus-follows-mouse max-scroll-amount="0%"
    }

    output "eDP-1" {
        scale 2
    }

    layout {
        gaps 8
        center-focused-column "never"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            width 2
            active-color "#bd93f9"
            inactive-color "#44475a"
        }

        border {
            off
        }
    }

    spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "XDG_DATA_DIRS"
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "${random-wallpaper}"
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
    spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f -c 282a36" "timeout" "600" "niri msg action power-off-monitors" "resume" "niri msg action power-on-monitors" "before-sleep" "swaylock -f -c 282a36"

    prefer-no-csd

    screenshot-path null

    environment {
        XDG_CURRENT_DESKTOP "niri"
    }

    cursor {
        xcursor-size 24
    }

    animations {
        window-open {
            duration-ms 200
            curve "ease-out-expo"
        }
        window-close {
            duration-ms 150
            curve "ease-out-quad"
        }
        workspace-switch {
            duration-ms 200
            curve "ease-out-expo"
        }
    }

    window-rule {
        geometry-corner-radius 6
        clip-to-geometry true
    }

    binds {
        Mod+Return { spawn "ghostty"; }
        Mod+Q { close-window; }
        Mod+Space { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
        Mod+Shift+E { quit; }

        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-up; }
        Mod+J { focus-window-down; }

        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+L { move-column-right; }
        Mod+Ctrl+K { move-window-up; }
        Mod+Ctrl+J { move-window-down; }

        Mod+Shift+H { set-column-width "-10%"; }
        Mod+Shift+L { set-column-width "+10%"; }
        Mod+Shift+K { set-window-height "-10%"; }
        Mod+Shift+J { set-window-height "+10%"; }

        Mod+V { toggle-window-floating; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        Mod+Escape { spawn "swaylock" "-f" "-c" "282a36"; }
        Mod+Shift+V { spawn "noctalia-shell" "ipc" "call" "launcher" "clipboard"; }

        Print { screenshot; }
        Mod+Print { screenshot-window; }
        Ctrl+Print { screenshot-screen; }

        XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86MonBrightnessUp { spawn "brightnessctl" "s" "5%+"; }
        XF86MonBrightnessDown { spawn "brightnessctl" "s" "5%-"; }

        Mod+Mouse-Left { move-window; }
        Mod+Mouse-Right { resize-window; }

        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { reset-window-height; }
        Mod+C { center-column; }
    }
  '';

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
      exec = "swaylock -f -c 282a36";
      icon = "system-lock-screen";
      categories = [ "System" ];
    };
    logout = {
      name = "Logout";
      exec = "niri msg action quit";
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
