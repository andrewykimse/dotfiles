{ pkgs, lib, nixgl, nvidiaLibDir, ... }:
let
  # Ubuntu's AppArmor blocks unprivileged userns, and the SUID sandbox can't live in /nix/store
  chromium = pkgs.chromium.override { commandLineArgs = "--no-sandbox"; };
  # nixgl is only passed to non-NixOS hosts; .desktop Exec lines call bare `chromium`, so PATH picks up the wrapper
  chromiumNixGL = pkgs.runCommand "chromium-nixgl" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin
    ln -s ${chromium}/share $out/share
    makeWrapper ${nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLDefault}/bin/nixGL $out/bin/chromium \
      --add-flags "${chromium}/bin/chromium" \
      ${lib.optionalString (nvidiaLibDir != null) "--set GBM_BACKENDS_PATH ${nvidiaLibDir}/gbm"}
  '';
in
{
  imports = [
    ./shell.nix
    ./git.nix
    ./terminal.nix
    ./dev.nix
  ];

  home.packages = [ 
    pkgs.nh 
    pkgs.iperf3 
    pkgs.spotify-player 
    pkgs.signal-desktop
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    (if nixgl != null then chromiumNixGL else chromium)
  ];

  # home.username and home.homeDirectory are set per-host

  home.sessionPath = [ "$HOME/.local/bin" ];

  # Allow unfree for nix-shell / nix-env (channel commands)
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  # Allow unfree for flake commands (nix run/shell) — still needs --impure
  home.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
