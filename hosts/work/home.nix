{ config, pkgs, nixgl, hyprland-config, ... }:
let
  nixGLPkg = nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLDefault;
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
  imports = [
    ../../modules/common.nix
    hyprland-config.homeManagerModules.default
    ../../modules/quickshell.nix
    ../../modules/work.nix
  ];

  hyprland-config = {
    enable      = true;
    package     = hyprlandWrapped;
    lockCommand = "${pkgs.hyprlock}/bin/hyprlock";
    extraLua    = ''hl.config({ input = { kb_options = "caps:escape" } })'';
    monitors = [
      { output = "desc:Apple Computer Inc StudioDisplay"; mode = "5120x2880@60"; position = "auto"; scale = 2; }
      { output = "desc:Dell Inc. DELL U3425WE";           mode = "3440x1440@60"; position = "auto"; scale = 1; }
      { output = ""; mode = "preferred"; position = "auto"; scale = 1; }
    ];
    extraEnv = [
      { _args = [ "PATH" "${config.home.homeDirectory}/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin" ]; }
      { _args = [ "XDG_DATA_DIRS" "${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share" ]; }
    ];
  };

  home.username = "akim7";
  home.homeDirectory = "/home/akim7";


  home.file.".local/bin/hyprlock-auth" = {
    executable = true;
    text = ''
      #!/usr/bin/python3
      import subprocess, sys, os
      password = sys.stdin.read().split("\0")[0].strip()
      if not password:
          sys.exit(1)
      user = os.environ.get("PAM_USER", "")
      result = subprocess.run(
          ["/usr/bin/pamtester", "login", user, "authenticate"],
          input=password + "\n", capture_output=True, text=True
      )
      sys.exit(result.returncode)
    '';
  };

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
    pkgs.hyprlock
    pkgs.pulsemixer
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
}
