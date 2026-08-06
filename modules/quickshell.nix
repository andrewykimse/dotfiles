{ pkgs, ricelin, hyprsphere, hyprland-config, config, lib, nvibrant-src ? null, nvidia-open-gpu-595-84 ? null, ... }:
let
  cfg = config.services.quickshell-ricelin;
  qs = cfg.package;

  # Digital vibrance on Wayland via /dev/nvidia-modeset ioctls; the ioctl ABI
  # is pinned to a specific driver release, so this is built against the
  # exact open-gpu-kernel-modules tag matching this host's driver (595.84)
  # rather than nvibrant's own multi-version PyPI build.
  nvibrant = if nvibrant-src != null && nvidia-open-gpu-595-84 != null
    then pkgs.stdenv.mkDerivation {
      pname = "nvibrant";
      version = "595.84";
      src = nvibrant-src;
      nativeBuildInputs = [ pkgs.meson pkgs.ninja ];
      postPatch = ''
        rm -rf open-gpu
        cp -r ${nvidia-open-gpu-595-84} open-gpu
        chmod -R u+w open-gpu
      '';
      mesonBuildType = "release";
      installPhase = ''
        mkdir -p $out/bin
        cp nvibrant $out/bin/nvibrant
      '';
    }
    else null;

  draculaTheme = pkgs.writeText "Theme.qml"
    (builtins.readFile "${hyprland-config}/quickshell/Theme.qml");

  pillOverride = pkgs.writeText "Pill.qml"
    (builtins.readFile "${hyprland-config}/quickshell/pill/Pill.qml");

  glyphIconOverride = pkgs.writeText "GlyphIcon.qml"
    (builtins.readFile "${hyprland-config}/quickshell/pill/GlyphIcon.qml");

  batterySurface = pkgs.writeText "Battery.qml"
    (builtins.readFile "${hyprland-config}/quickshell/pill/Battery.qml");

  devicesOverride = pkgs.writeText "Devices.qml"
    (builtins.readFile "${hyprland-config}/quickshell/pill/Singletons/Devices.qml");

  mixerOverride = pkgs.writeText "Mixer.qml"
    (builtins.readFile "${hyprland-config}/quickshell/pill/Mixer.qml");

  # Patch the Ricelin quickshell config:
  #   1. Replace all Theme.qml files with the Dracula-adapted version
  #   2. Remap hardcoded ~/Ricelin/wallpapers → ~/sources/dotfiles/wallpapers
  #   3. Replace pill/Pill.qml, pill/GlyphIcon.qml and pill/Mixer.qml with our
  #      battery-percentage/power-profile/internal-backlight-augmented
  #      versions, pill/Singletons/Devices.qml with a version that adds
  #      brightnessctl-backed backlight control, and add the new
  #      pill/Battery.qml surface
  quickshellConfig = pkgs.runCommand "quickshell-ricelin-config" {
    nativeBuildInputs = [ pkgs.gnused pkgs.python3 ];
  } ''
    cp -r ${ricelin}/configs/quickshell $out
    chmod -R u+w $out
    find $out -name "Theme.qml" -exec cp ${draculaTheme} {} \;
    sed -i 's|/Ricelin/wallpapers|/sources/dotfiles/wallpapers|g' $out/pill/Singletons/Walls.qml
    cp ${pillOverride} $out/pill/Pill.qml
    cp ${glyphIconOverride} $out/pill/GlyphIcon.qml
    cp ${batterySurface} $out/pill/Battery.qml
    cp ${devicesOverride} $out/pill/Singletons/Devices.qml
    cp ${mixerOverride} $out/pill/Mixer.qml
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
    cp ${hyprland-config}/quickshell/hyprsphere.json $out/hyprsphere/hyprsphere.json
  '';
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
    ] ++ lib.optional (nvibrant != null) nvibrant;

    fonts.fontconfig.enable = true;

    xdg.configFile."quickshell".source = quickshellConfig;
  };
}
