{ config, pkgs, hyprland-config, ... }:
let
  qs = config.services.quickshell-ricelin.package;
  screenshot-area = pkgs.writeShellScript "screenshot-area" ''
    grim -g "$(slurp)" - | wl-copy
  '';
  screenshot-full = pkgs.writeShellScript "screenshot-full" ''
    grim - | wl-copy
  '';
  record-area = pkgs.writeShellScript "record-area" ''
    mkdir -p "$HOME/Videos"
    exec ${pkgs.wf-recorder}/bin/wf-recorder -g "$(slurp)" \
      -f "$HOME/Videos/$(date +%Y-%m-%d-%H%M%S).mp4"
  '';
  # wf-recorder prompts interactively when several outputs exist, which hangs
  # when launched from a menu, so pick the focused one explicitly.
  record-full = pkgs.writeShellScript "record-full" ''
    mkdir -p "$HOME/Videos"
    output=$(hyprctl -j activeworkspace | ${pkgs.jq}/bin/jq -r .monitor)
    exec ${pkgs.wf-recorder}/bin/wf-recorder -o "$output" \
      -f "$HOME/Videos/$(date +%Y-%m-%d-%H%M%S).mp4"
  '';
  record-stop = pkgs.writeShellScript "record-stop" ''
    pkill -INT -x wf-recorder
  '';
  new-browser-window = pkgs.writeShellScript "new-browser-window" ''
    desktop=$(${pkgs.xdg-utils}/bin/xdg-settings get default-web-browser)
    desktop_file=$(find /run/current-system/sw/share/applications $HOME/.local/share/applications $HOME/.nix-profile/share/applications /usr/share/applications -name "$desktop" 2>/dev/null | head -1)
    binary=$(${pkgs.gnugrep}/bin/grep -m1 '^Exec=' "$desktop_file" | ${pkgs.gnused}/bin/sed 's/^Exec=//;s/ %.//g')
    exec ''${binary:-xdg-open} --new-window
  '';
in
{
  home.packages = with pkgs; [
    hyprpaper
    hypridle
    hyprpolkitagent
    grim
    slurp
    wf-recorder
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    pavucontrol
  ];

  # Registers hyprland.portal in the profile's portal dir and points the frontend
  # at it, so ScreenCast (screen recording and sharing) has a backend.
  xdg.portal = {
    enable = true;
    extraPortals = [
      config.wayland.windowManager.hyprland.finalPortalPackage
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    settings = {
      mod          = { _var = "SUPER"; };
      terminal     = { _var = "ghostty"; };
      lock         = { _var = "hyprlock"; };
      claude_here  = { _var = "${hyprland-config}/scripts/claude-here.sh"; };
      browser      = { _var = "${new-browser-window}"; };
      monitor  = [
        { output = "eDP-1"; mode = "preferred"; position = "auto"; scale = 2; }
        { output = "";      mode = "preferred"; position = "auto"; scale = 1; }
      ];
    };
    extraConfig = builtins.readFile "${hyprland-config}/hypr/hyprland.lua" + ''

      hl.on("hyprland.start", function()
        hl.exec_cmd("${pkgs.awww}/bin/awww-daemon")
        hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store")
        hl.exec_cmd("${qs}/bin/quickshell -p ${config.xdg.configHome}/quickshell/pill")
        hl.exec_cmd("${qs}/bin/quickshell -p ${config.xdg.configHome}/quickshell/launcher")
        hl.exec_cmd("${qs}/bin/quickshell -p ${config.xdg.configHome}/quickshell/rishot")
        hl.exec_cmd("sh -c 'QML2_IMPORT_PATH=${pkgs.qt6Packages.qt5compat}/lib/qt-6/qml ${qs}/bin/quickshell -c hyprsphere'")
      end)

      local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"
      hl.bind("SUPER + Space",  hl.dsp.exec_cmd(scripts .. "/launcher.sh"))
      hl.bind("SUPER + V",      hl.dsp.exec_cmd(scripts .. "/clipboard.sh"))
      hl.bind("SUPER + B",      hl.dsp.exec_cmd(scripts .. "/wallpaper.sh"))
      hl.bind("SUPER + W",      hl.dsp.exec_cmd(scripts .. "/wallpaper-picker.sh"))

      hl.bind("SUPER + Tab", function()
        hl.dispatch(hl.dsp.submap("hyprsphere"))
        hl.dispatch(hl.dsp.exec_cmd("${qs}/bin/qs -c hyprsphere ipc call hyprsphere toggle"))
      end)

      hl.define_submap("hyprsphere", function()
        hl.bind("SUPER + Super_L", function()
          hl.dispatch(hl.dsp.exec_cmd("${qs}/bin/qs -c hyprsphere ipc call hyprsphere commit"))
          hl.dispatch(hl.dsp.submap("reset"))
        end, { release = true })
        hl.bind("SUPER + Super_R", function()
          hl.dispatch(hl.dsp.exec_cmd("${qs}/bin/qs -c hyprsphere ipc call hyprsphere commit"))
          hl.dispatch(hl.dsp.submap("reset"))
        end, { release = true })

        hl.bind("Escape", function()
          hl.dispatch(hl.dsp.exec_cmd("${qs}/bin/qs -c hyprsphere ipc call hyprsphere cancel"))
          hl.dispatch(hl.dsp.submap("reset"))
        end)
      end)
    '';
  };

  xdg.configFile."hypr/hyprland.conf" = { text = "# See hyprland.lua"; force = true; };
  xdg.configFile."hypr/hyprpaper.conf".source = "${hyprland-config}/hypr/hyprpaper.conf";
  xdg.configFile."hypr/hyprlock.conf".source  = "${hyprland-config}/hypr/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source  = "${hyprland-config}/hypr/hypridle.conf";

  # Wallpaper setter — called by Walls.qml ("set <path>") and Super+B keybind (no args → random)
  xdg.configFile."hypr/scripts/wallpaper.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      CMD="''${1:-random}"
      WALL_PATH="''${2:-}"
      STATE_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/ricelin-wallpaper"
      _apply() {
        ${pkgs.awww}/bin/awww img "$1" \
          --transition-type wave \
          --transition-fps 60 \
          --transition-duration 1
        mkdir -p "$(dirname "$STATE_FILE")"
        printf '%s\n' "$1" > "$STATE_FILE"
      }
      case "$CMD" in
        set)
          [ -n "$WALL_PATH" ] || { echo "Usage: wallpaper.sh set <path>" >&2; exit 1; }
          _apply "$WALL_PATH"
          ;;
        random)
          img=$(find "$HOME/sources/dotfiles/wallpapers" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) 2>/dev/null | ${pkgs.coreutils}/bin/shuf -n 1)
          [ -n "$img" ] && _apply "$img"
          ;;
        *) echo "Unknown command: $CMD" >&2; exit 1 ;;
      esac
    '';
  };

  # IPC bridge scripts — call quickshell pill/sidebar surfaces via qs CLI
  xdg.configFile."hypr/scripts/launcher.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      mon=$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.monitor')
      ${qs}/bin/qs -c pill ipc call pill launcher "$mon"
    '';
  };

  xdg.configFile."hypr/scripts/clipboard.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      mon=$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.monitor')
      ${qs}/bin/qs -c pill ipc call pill clipboard "$mon"
    '';
  };

  xdg.configFile."hypr/scripts/sidebar.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      mon=$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.monitor')
      ${qs}/bin/qs -c sidebar ipc call sidebar toggle "$mon"
    '';
  };

  xdg.configFile."hypr/scripts/lock.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      hyprlock
    '';
  };

  xdg.configFile."hypr/scripts/wallpaper-picker.sh" = {
    executable = true;
    text = ''
      #!/bin/sh
      mon=$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.monitor')
      ${qs}/bin/qs -c pill ipc call pill wallpaper "$mon"
    '';
  };

  # Generates 512px thumbnail previews for the wallpaper picker strip
  xdg.configFile."hypr/scripts/wallpaper-thumbs.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      WP_DIR="$HOME/sources/dotfiles/wallpapers"
      THUMB_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/ricelin-wp-thumbs"
      mkdir -p "$THUMB_DIR"
      for thumb in "$THUMB_DIR"/*.png; do
        [ -f "$thumb" ] || continue
        src="$WP_DIR/$(basename "''${thumb%.png}")"
        [ -f "$src" ] || rm -f "$thumb"
      done
      while IFS= read -r -d $'\0' img; do
        name="$(basename "$img")"
        thumb="$THUMB_DIR/''${name}.png"
        [ -f "$thumb" ] && continue
        ${pkgs.imagemagick}/bin/convert \
          -thumbnail 512x512^ -gravity center -extent 512x512 \
          "$img" "$thumb" 2>/dev/null || true
      done < <(find "$WP_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 2>/dev/null || true)
    '';
  };

  # Generates 256px thumbnail previews for clipboard image entries
  xdg.configFile."hypr/scripts/cliphist-thumbs.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      THUMB_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs"
      mkdir -p "$THUMB_DIR"
      mapfile -t current_ids < <(${pkgs.cliphist}/bin/cliphist list 2>/dev/null | awk -F'\t' '{print $1}')
      for thumb in "$THUMB_DIR"/*.png; do
        [ -f "$thumb" ] || continue
        id="$(basename "''${thumb%.png}")"
        found=0
        for cid in "''${current_ids[@]}"; do [ "$cid" = "$id" ] && found=1 && break; done
        [ "$found" = "0" ] && rm -f "$thumb"
      done
      while IFS=$'\t' read -r id preview; do
        [[ "$preview" =~ ^\[\[\ binary\ data\ .*\.(png|jpg|jpeg|gif|bmp|webp) ]] || continue
        thumb="$THUMB_DIR/''${id}.png"
        [ -f "$thumb" ] && continue
        printf '%s' "$id" | ${pkgs.cliphist}/bin/cliphist decode 2>/dev/null \
          | ${pkgs.imagemagick}/bin/convert - \
            -thumbnail 256x256^ -gravity center -extent 256x256 \
            "$thumb" 2>/dev/null || true
      done < <(${pkgs.cliphist}/bin/cliphist list 2>/dev/null)
    '';
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
    record-area = {
      name = "Record (Area)";
      exec = "${record-area}";
      icon = "media-record";
      categories = [ "Utility" ];
    };
    record-full = {
      name = "Record (Full)";
      exec = "${record-full}";
      icon = "media-record";
      categories = [ "Utility" ];
    };
    record-stop = {
      name = "Record (Stop)";
      exec = "${record-stop}";
      icon = "media-playback-stop";
      categories = [ "Utility" ];
    };
  };
}
