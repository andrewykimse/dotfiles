{ config, pkgs, nixgl, ... }:
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
    ../../modules/hyprland.nix
    ../../modules/quickshell.nix
    ../../modules/work.nix
  ];

  wayland.windowManager.hyprland.package = hyprlandWrapped;

  wayland.windowManager.hyprland.extraConfig = pkgs.lib.mkAfter ''
    hl.config({ input = { kb_options = "caps:escape" } })
  '';

  wayland.windowManager.hyprland.settings.lock = pkgs.lib.mkForce { _var = "${pkgs.hyprlock}/bin/hyprlock"; };

  wayland.windowManager.hyprland.settings.monitor = pkgs.lib.mkForce [
    { output = "desc:Apple Computer Inc StudioDisplay"; mode = "5120x2880@60"; position = "auto"; scale = 2; }
    { output = "desc:Dell Inc. DELL U3425WE";           mode = "3440x1440@60"; position = "auto"; scale = 1; }
    { output = ""; mode = "preferred"; position = "auto"; scale = 1; }
  ];

  wayland.windowManager.hyprland.settings.env = [
    { _args = [ "PATH" "${config.home.homeDirectory}/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin" ]; }
    { _args = [ "XDG_DATA_DIRS" "${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share" ]; }
  ];

  xdg.configFile."hypr/hypridle.conf" = pkgs.lib.mkForce {
    text = ''
      general {
        lock_cmd = ${pkgs.hyprlock}/bin/hyprlock
        before_sleep_cmd = loginctl lock-session
      }

      listener {
        timeout = 300
        on-timeout = ${pkgs.hyprlock}/bin/hyprlock
      }

      listener {
        timeout = 600
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
      }
    '';
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
