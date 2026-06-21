{ pkgs, ... }:
{
  programs.ghostty.enable = pkgs.lib.mkForce false;

  xdg.configFile."ghostty/config".text = ''
    theme = Dracula
    command = ${pkgs.zsh}/bin/zsh
  '';

  home.packages = with pkgs; [ awscli2 cachix jira-cli-go ];
}
