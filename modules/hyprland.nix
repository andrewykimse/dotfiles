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
    fuzzel
    brightnessctl
    playerctl
    pavucontrol
    anyrun
    socat
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$menu" = "anyrun";
      "$lock" = "hyprlock";

      monitor = [
        "eDP-1, preferred, auto, 2"
        ", 5120x2880, auto, 2"
        ", preferred, auto, 1"
      ];

      bindl = [
        ", switch:on:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, disable\""
        ", switch:off:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, preferred, auto, 2\""
      ];

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_DATA_DIRS"
        "systemctl --user restart xdg-desktop-portal"
        "waybar"
        "mako"
        "hyprpaper"
        "sleep 1 && ${random-wallpaper}"
        "hypridle"
        "wl-paste --watch cliphist store"
        "systemctl --user start hyprpolkitagent"
        ''socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do case "$line" in monitoradded*|monitorremoved*) sleep 1 && pkill waybar; waybar & ;; esac; done''
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
        "$mod, Space, exec, pkill anyrun || $menu"
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
        "$mod SHIFT, V, exec, cliphist list | anyrun --plugins ${pkgs.anyrun}/lib/libstdin.so | cliphist decode | wl-copy"

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
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 muted";
        format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
      };
      network = {
        format-wifi = "󰤨 {signalStrength}%";
        format-ethernet = "󰈀 {ipaddr}";
        format-disconnected = "󰤭 ";
        tooltip-format = "{ifname}: {ipaddr}";
      };
      battery = {
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
      };
    };
    style = ''
      * { font-family: "JetBrainsMono Nerd Font", monospace; font-size: 12px; }
      window#waybar { background: rgba(40, 42, 54, 0.85); color: #f8f8f2; }
      #workspaces button.active { background: #bd93f9; color: #282a36; }
    '';
  };

  xdg.configFile."anyrun/config.ron".text = ''
    Config(
      x: Fraction(0.5),
      y: Absolute(0),
      width: Absolute(800),
      height: Absolute(1),
      hide_icons: false,
      ignore_exclusive_zones: false,
      layer: Overlay,
      hide_plugin_info: false,
      close_on_click: true,
      show_results_immediately: true,
      max_entries: Some(12),
      plugins: [
        // type to search apps
        "${pkgs.anyrun}/lib/libapplications.so",
        // prefix `:` to run shell commands (e.g. `:systemctl restart NetworkManager`)
        "${pkgs.anyrun}/lib/libshell.so",
        // prefix `?` to web search
        "${pkgs.anyrun}/lib/libwebsearch.so",
        // prefix `:dp` to change display resolution/refresh rate
        "${pkgs.anyrun}/lib/librandr.so",
        // prefix `:nix` to run nix packages without installing
        "${pkgs.anyrun}/lib/libnix_run.so",
        // used by Super+Shift+V for clipboard history
        "${pkgs.anyrun}/lib/libstdin.so",
      ],
    )
  '';

  xdg.configFile."anyrun/shell.ron".text = ''
    Config(
      prefix: ":",
      shell: None,
    )
  '';

  xdg.configFile."anyrun/nix-run.ron".text = ''
    Config(
      prefix: ":nix",
      channel: "nixpkgs-unstable",
      max_entries: Some(10),
      allow_unfree: true,
    )
  '';

  xdg.configFile."anyrun/randr.ron".text = ''
    Config(
      prefix: ":dp",
      max_entries: Some(10),
    )
  '';

  xdg.configFile."anyrun/style.css".text = ''
    @define-color accent #bd93f9;
    @define-color bg-color rgba(40, 42, 54, 0.92);
    @define-color fg-color #f8f8f2;
    @define-color desc-color #6272a4;

    window {
      background: transparent;
    }

    box.main {
      padding: 12px;
      margin: 10px;
      border-radius: 8px;
      border: 2px solid @accent;
      background-color: @bg-color;
    }

    text {
      min-height: 30px;
      padding: 5px;
      border-radius: 5px;
      color: @fg-color;
    }

    .matches {
      background-color: transparent;
      border-radius: 8px;
    }

    box.plugin:first-child {
      margin-top: 5px;
    }

    list.plugin {
      background-color: transparent;
    }

    label.match {
      color: @fg-color;
      font-size: 14px;
    }

    label.match.description {
      font-size: 10px;
      color: @desc-color;
    }

    .match {
      background: transparent;
      padding: 4px 8px;
      border-radius: 4px;
    }

    .match:selected {
      background: alpha(@accent, 0.3);
      border-left: 3px solid @accent;
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
