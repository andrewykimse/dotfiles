{ config, pkgs, lib, ... }:
{
  programs.ghostty.enable = pkgs.lib.mkForce false;

  # Prefer the locally installed claude over the nix-managed one
  programs.zsh.initContent = lib.mkAfter ''
    export PATH="$HOME/.local/bin:$PATH"
  '';

  xdg.configFile."ghostty/config".text = ''
    theme = Dracula
    command = ${pkgs.zsh}/bin/zsh
  '';

  # Ubuntu's /usr/libexec/xdg-desktop-portal wins over the nix one via
  # /usr/lib/systemd/user, and it reads the unprefixed variable rather than the
  # NIX_-prefixed one home-manager sets. Without this it only scans /usr/share
  # and never finds hyprland.portal, leaving ScreenCast with no backend.
  systemd.user.sessionVariables.XDG_DESKTOP_PORTAL_DIR =
    "${config.home.profileDirectory}/share/xdg-desktop-portal/portals";

  home.packages = with pkgs; [ awscli2 cachix jira-cli-go firefox ];
}
