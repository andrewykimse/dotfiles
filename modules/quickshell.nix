{ pkgs, ricelin, hyprsphere, config, lib, ... }:
let
  cfg = config.services.quickshell-ricelin;
  qs = cfg.package;

  draculaTheme = pkgs.writeText "Theme.qml"
    (builtins.readFile ../config/quickshell/Theme.qml);

  # Patch the Ricelin quickshell config:
  #   1. Replace all Theme.qml files with the Dracula-adapted version
  #   2. Remap hardcoded ~/Ricelin/wallpapers → ~/sources/dotfiles/wallpapers
  #   3. Remove nvibrant calls (binary not in nixpkgs)
  quickshellConfig = pkgs.runCommand "quickshell-ricelin-config" {
    nativeBuildInputs = [ pkgs.gnused pkgs.python3 ];
  } ''
    cp -r ${ricelin}/configs/quickshell $out
    chmod -R u+w $out
    find $out -name "Theme.qml" -exec cp ${draculaTheme} {} \;
    sed -i 's|/Ricelin/wallpapers|/sources/dotfiles/wallpapers|g' $out/pill/Singletons/Walls.qml
    sed -i '/nvibrant/d' $out/pill/Singletons/Devices.qml
    mkdir -p $out/hyprsphere
    cp ${hyprsphere}/shell.qml $out/hyprsphere/shell.qml
    chmod u+w $out/hyprsphere/shell.qml
    sed -i 's|"\$HOME/.local/share/applications/\*.desktop|"\$HOME/.nix-profile/share/applications/*.desktop \$HOME/.local/share/applications/*.desktop|' $out/hyprsphere/shell.qml
    # hyprctl dispatch with Lua dispatcher syntax needs hyprctl eval + hl.dispatch() wrapper
    sed -i 's|"hyprctl", "dispatch",|"hyprctl", "eval",|g' $out/hyprsphere/shell.qml
    sed -i "s|'hl\.dsp\.\(.*\)']);|'hl.dispatch(hl.dsp.\1)']);|g" $out/hyprsphere/shell.qml
    # Resolve named icons (e.g. "steam") to their highest-res file path so QML
    # uses file:// and scales smoothly, instead of image://icon/ which doesn't
    # do size fallback in quickshell's provider.
    cat > $out/hyprsphere/resolve-icon.sh << 'RESOLVE_EOF'
#!/usr/bin/env bash
ic="$1"
[ -z "$ic" ] && exit 1
case "$ic" in /*) [ -f "$ic" ] && echo "$ic" && exit 0 ;; esac
for sz in 512x512 256x256 128x128 scalable 64x64 48x48 32x32; do
  for base in "$HOME/.nix-profile/share/icons" /run/current-system/sw/share/icons; do
    for ext in png svg; do
      p="$base/hicolor/$sz/apps/$ic.$ext"
      [ -f "$p" ] && echo "$p" && exit 0
    done
  done
done
echo "$ic"
RESOLVE_EOF
    chmod +x $out/hyprsphere/resolve-icon.sh
    python3 - $out/hyprsphere/shell.qml << 'PYEOF'
import sys
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()
old = '"grep -E \'^(Name=|Icon=|StartupWMClass=|Exec=)\' \\"$f\\" 2>/dev/null; " +'
new = (
    '"grep -E \'^(Name=|StartupWMClass=|Exec=)\' \\"$f\\" 2>/dev/null; " +\n'
    '            "ic=$(grep -m1 \'^Icon=\' \\"$f\\" 2>/dev/null | cut -d= -f2-); '
    'if [ -n \\"$ic\\" ]; then '
    'r=$($HOME/.config/quickshell/hyprsphere/resolve-icon.sh \\"$ic\\"); '
    'echo \\"Icon=$r\\"; fi; " +'
)
assert old in content, "Pattern not found in shell.qml!"
content = content.replace(old, new, 1)
with open(path, 'w') as f:
    f.write(content)
PYEOF
    cp -r ${hyprsphere}/lib $out/hyprsphere/lib
    cp ${../config/quickshell/hyprsphere.json} $out/hyprsphere/hyprsphere.json
  '';

  qt5compatQmlPath = "${pkgs.qt6Packages.qt5compat}/lib/qt-6/qml";
in
{
  options.services.quickshell-ricelin.package = lib.mkOption {
    type = lib.types.package;
    default = pkgs.quickshell;
    description = "Quickshell package — override with a nixGL-wrapped derivation on non-NixOS hosts";
  };

  config = {
    home.packages = with pkgs; [
      qs
      cliphist
      wl-clipboard
      ddcutil
      awww
      imagemagick
      jq
      inter
      noto-fonts-cjk-sans
      qt6Packages.qt5compat
    ];

    fonts.fontconfig.enable = true;

    xdg.configFile."quickshell".source = quickshellConfig;

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
        ${pkgs.quickshell}/bin/qs -c pill ipc call pill launcher "$mon"
      '';
    };

    xdg.configFile."hypr/scripts/clipboard.sh" = {
      executable = true;
      text = ''
        #!/bin/sh
        mon=$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.monitor')
        ${pkgs.quickshell}/bin/qs -c pill ipc call pill clipboard "$mon"
      '';
    };

    xdg.configFile."hypr/scripts/sidebar.sh" = {
      executable = true;
      text = ''
        #!/bin/sh
        mon=$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.monitor')
        ${pkgs.quickshell}/bin/qs -c sidebar ipc call sidebar toggle "$mon"
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
        ${pkgs.quickshell}/bin/qs -c pill ipc call pill wallpaper "$mon"
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

    wayland.windowManager.hyprland.extraConfig = ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("${pkgs.awww}/bin/awww-daemon")
        hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store")
        hl.exec_cmd("${qs}/bin/quickshell -p ${config.xdg.configHome}/quickshell/pill")
        hl.exec_cmd("${qs}/bin/quickshell -p ${config.xdg.configHome}/quickshell/launcher")
        hl.exec_cmd("${qs}/bin/quickshell -p ${config.xdg.configHome}/quickshell/rishot")
        hl.exec_cmd("sh -c 'QML2_IMPORT_PATH=${qt5compatQmlPath} ${qs}/bin/quickshell -c hyprsphere'")
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
}
