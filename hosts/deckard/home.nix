{ config, pkgs, lib, nixgl, ... }:
let
  nixGLPkg = nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLDefault;
in
{
  # SteamOS is not NixOS, so the Nix-built ghostty binary can't find the
  # system's real Mesa/OpenGL driver stack on its own. Disable the plain
  # install and wrap it with nixGL instead (same pattern as work/work-desktop).
  programs.ghostty.enable = lib.mkForce false;

  xdg.configFile."ghostty/config".text = ''
    theme = Dracula
    copy-on-select = clipboard
    command = ${pkgs.zsh}/bin/zsh
  '';

  home.packages = [
    (pkgs.runCommand "ghostty-nixgl" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      mkdir -p $out/bin $out/share/applications $out/share/icons $out/share/dbus-1/services
      cp -rs ${pkgs.ghostty}/share/ghostty $out/share/ 2>/dev/null || true
      cp -rs ${pkgs.ghostty}/share/icons/* $out/share/icons/ 2>/dev/null || true
      makeWrapper ${nixGLPkg}/bin/nixGL $out/bin/ghostty \
        --add-flags "${pkgs.ghostty}/bin/ghostty"
      # ghostty's .desktop/.service Exec/TryExec lines point at either a bare
      # "ghostty" command or an absolute store path ending in bin/ghostty
      # depending on nixpkgs version, so match up to the last "ghostty" rather
      # than the exact package path.
      sed -e "s#^Exec=.*ghostty#Exec=$out/bin/ghostty#" \
          -e "s#^TryExec=.*ghostty#TryExec=$out/bin/ghostty#" \
          -e "s/DBusActivatable=true/DBusActivatable=false/" \
          ${pkgs.ghostty}/share/applications/com.mitchellh.ghostty.desktop \
          > $out/share/applications/com.mitchellh.ghostty.desktop
      sed -e "s#^Exec=.*ghostty#Exec=$out/bin/ghostty#" \
          ${pkgs.ghostty}/share/dbus-1/services/com.mitchellh.ghostty.service \
          > $out/share/dbus-1/services/com.mitchellh.ghostty.service
    '')
  ];

  home.username = "deck";
  home.homeDirectory = "/home/deck";

  # Set any non-internal display to 4K@60 at login.
  # For hotplug after login, run `set-external-4k` manually.
  home.file.".local/bin/set-external-4k" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      sleep 5
      kscreen-doctor -o 2>/dev/null \
        | awk '/^Output:/ && !/eDP/ { print $2 }' \
        | while read -r output; do
            kscreen-doctor "output.$output.enable" 2>/dev/null || true
            kscreen-doctor "output.$output.mode.3840x2160@60" 2>/dev/null || true
          done
    '';
  };

  systemd.user.services.set-external-4k = {
    Unit = {
      Description = "Set external display to 4K@60";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/set-external-4k";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
