{ config, pkgs, nixgl, noctalia, ... }:
let
  nixGLPkg = nixgl.packages.${pkgs.system}.nixGLDefault;
  noctaliaPkg = noctalia.packages.${pkgs.system}.default;
  hyprlandSystem = (pkgs.runCommand "hyprland-system" {} ''
    mkdir -p $out/bin $out/share
    ln -s /usr/bin/Hyprland $out/bin/Hyprland
    ln -s /usr/bin/hyprctl $out/bin/hyprctl
  '').overrideAttrs (_: { passthru.override = _: hyprlandSystem; });
in
{
  imports = [
    ../../modules/hyprland.nix
    ../../modules/noctalia.nix
    ../../modules/work.nix
  ];

  wayland.windowManager.hyprland.package = hyprlandSystem;

  wayland.windowManager.hyprland.settings.env = [
    "PATH,${config.home.homeDirectory}/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin"
    "XDG_DATA_DIRS,${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share"
    "GBM_BACKEND,nvidia-drm"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    "LIBVA_DRIVER_NAME,nvidia"
    "XDG_SESSION_TYPE,wayland"
  ];

  wayland.windowManager.hyprland.settings.monitor = pkgs.lib.mkForce [
    "desc:Dell Inc. DELL U3425WE, 3440x1440@60, auto, 1"
    ", preferred, auto, 1"
  ];


  home.packages = [
    (pkgs.runCommand "ghostty-nixgl" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      mkdir -p $out/bin $out/share/applications $out/share/icons $out/share/dbus-1/services
      cp -rs ${pkgs.ghostty}/share/ghostty $out/share/ 2>/dev/null || true
      cp -rs ${pkgs.ghostty}/share/icons/* $out/share/icons/ 2>/dev/null || true
      makeWrapper ${nixGLPkg}/bin/nixGL $out/bin/ghostty \
        --add-flags "${pkgs.ghostty}/bin/ghostty"
      substitute ${pkgs.ghostty}/share/applications/com.mitchellh.ghostty.desktop \
        $out/share/applications/com.mitchellh.ghostty.desktop \
        --replace-fail "${pkgs.ghostty}/bin/ghostty" "$out/bin/ghostty" \
        --replace-fail "DBusActivatable=true" "DBusActivatable=false"
      substitute ${pkgs.ghostty}/share/dbus-1/services/com.mitchellh.ghostty.service \
        $out/share/dbus-1/services/com.mitchellh.ghostty.service \
        --replace-fail "${pkgs.ghostty}/bin/ghostty" "$out/bin/ghostty"
    '')
  ];

  programs.noctalia-shell.package = pkgs.lib.mkForce (pkgs.runCommand "noctalia-shell-nixgl" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    makeWrapper ${nixGLPkg}/bin/nixGL $out/bin/noctalia-shell \
      --add-flags "${noctaliaPkg}/bin/noctalia-shell"
  '');

  home.username = "akim7";
  home.homeDirectory = "/home/akim7";
}
