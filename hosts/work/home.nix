{ config, pkgs, nixgl, ... }:
let
  nixGLPkg = nixgl.packages.${pkgs.system}.nixGLDefault;
  hyprlandWrapped = (pkgs.runCommand "hyprland-nixgl" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin $out/share
    cp -rs ${pkgs.hyprland}/share/* $out/share/ 2>/dev/null || true
    makeWrapper ${nixGLPkg}/bin/nixGL $out/bin/Hyprland \
      --add-flags "${pkgs.hyprland}/bin/Hyprland" \
      --prefix LD_LIBRARY_PATH : "${pkgs.wayland}/lib"
    makeWrapper ${nixGLPkg}/bin/nixGL $out/bin/hyprctl \
      --add-flags "${pkgs.hyprland}/bin/hyprctl" \
      --prefix LD_LIBRARY_PATH : "${pkgs.wayland}/lib"
  '').overrideAttrs (_: { passthru.override = _: hyprlandWrapped; });
in
{
  imports = [ ../../modules/hyprland.nix ];

  wayland.windowManager.hyprland.package = hyprlandWrapped;

  wayland.windowManager.hyprland.settings.env = [
    "PATH,${config.home.homeDirectory}/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin"
  ];

  wayland.windowManager.hyprland.settings.monitor = pkgs.lib.mkForce [ ",preferred,auto,1" ];

  home.username = "akim7";
  home.homeDirectory = "/home/akim7";

  programs.ghostty.enable = pkgs.lib.mkForce false;

  xdg.configFile."ghostty/config".text = ''
    theme = Dracula
    command = ${pkgs.zsh}/bin/zsh
  '';

  home.activation.hyprlandSession = let
    desktopFile = pkgs.writeText "hyprland.desktop" ''
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=${config.home.homeDirectory}/.nix-profile/bin/Hyprland
Type=Application
DesktopNames=Hyprland
'';
  in config.lib.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/sudo -n ln -sf ${desktopFile} /usr/share/wayland-sessions/hyprland.desktop 2>/dev/null || echo "NOTE: run 'sudo ln -sf ${desktopFile} /usr/share/wayland-sessions/hyprland.desktop' to update the Hyprland session entry"
  '';

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
}
