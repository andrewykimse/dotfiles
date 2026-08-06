{ config, pkgs, nixgl, ... }:
let
  nixGLPkg = nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLDefault;
  hyprlandSystem = (pkgs.runCommand "hyprland-system" {} ''
    mkdir -p $out/bin $out/share
    ln -s /usr/bin/Hyprland $out/bin/Hyprland
    ln -s /usr/bin/hyprctl $out/bin/hyprctl
  '').overrideAttrs (_: { passthru.override = _: hyprlandSystem; });
in
{
  imports = [
    ../../modules/common.nix
    ../../modules/hyprland.nix
    ../../modules/quickshell.nix
    ../../modules/work.nix
  ];

  wayland.windowManager.hyprland.package = hyprlandSystem;

  wayland.windowManager.hyprland.settings.monitor = pkgs.lib.mkForce [
    { output = "desc:Dell Inc. DELL U3425WE"; mode = "3440x1440@60"; position = "auto"; scale = 1; }
    { output = ""; mode = "preferred"; position = "auto"; scale = 1; }
  ];

  wayland.windowManager.hyprland.settings.env = [
    { _args = [ "PATH" "${config.home.homeDirectory}/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin" ]; }
    { _args = [ "XDG_DATA_DIRS" "${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share" ]; }
    { _args = [ "GBM_BACKEND" "nvidia-drm" ]; }
    { _args = [ "__GLX_VENDOR_LIBRARY_NAME" "nvidia" ]; }
    { _args = [ "LIBVA_DRIVER_NAME" "nvidia" ]; }
    { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
  ];


  home.packages = [
    pkgs.pulsemixer
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

  services.quickshell-ricelin.package = pkgs.runCommand "quickshell-nixgl" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir -p $out/bin
    makeWrapper ${nixGLPkg}/bin/nixGL $out/bin/quickshell \
      --add-flags "${pkgs.quickshell}/bin/quickshell"
  '';

  home.username = "akim7";
  home.homeDirectory = "/home/akim7";
}
