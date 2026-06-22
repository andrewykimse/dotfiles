{ ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./terminal.nix
    ./dev.nix
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
