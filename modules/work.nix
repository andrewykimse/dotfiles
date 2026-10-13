{ config, pkgs, lib, ... }:
{
  # ghostty itself is installed per-host via a nixGL wrapper
  programs.ghostty = {
    package = null;
    systemd.enable = false;
    settings.command = "${pkgs.zsh}/bin/zsh";
  };

  # Prefer the locally installed claude over the nix-managed one
  programs.zsh.initContent = lib.mkAfter ''
    export PATH="$HOME/.local/bin:$PATH"
  '';

  # Ubuntu's /usr/libexec/xdg-desktop-portal wins over the nix one via
  # /usr/lib/systemd/user, and it reads the unprefixed variable rather than the
  # NIX_-prefixed one home-manager sets. Without this it only scans /usr/share
  # and never finds hyprland.portal, leaving ScreenCast with no backend.
  systemd.user.sessionVariables.XDG_DESKTOP_PORTAL_DIR =
    "${config.home.profileDirectory}/share/xdg-desktop-portal/portals";

  home.packages = with pkgs; [ awscli2 cachix jira-cli-go firefox ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
      "x-scheme-handler/latticent" = "latticent-handler.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      "x-scheme-handler/zoommtg" = "us.zoom.Zoom.desktop";
      "x-scheme-handler/zoomus" = "us.zoom.Zoom.desktop";
    };
  };
}
