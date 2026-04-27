{ config, pkgs, neovim-config, monkeyterm, viaterm, ... }:
{
  # home.username and home.homeDirectory are set per-host

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    htop
    curl
    wget
    btop
    brave
    nix-search-cli
    claude-code
    neovim-config.packages.${pkgs.system}.default
  ] ++ pkgs.lib.optionals (monkeyterm != null) [
    monkeyterm.packages.${pkgs.system}.default
  ] ++ pkgs.lib.optionals (viaterm != null) [
    viaterm.packages.${pkgs.system}.default
  ];

  xdg.configFile."nvim".source = "${neovim-config}/nvim";

  # Allow unfree for nix-shell / nix-env (channel commands)
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  # Allow unfree for flake commands (nix run/shell) — still needs --impure
  home.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";

  programs.ghostty = {
    enable = true;
    settings = {
      theme = "Dracula";
    };
  };

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = builtins.readFile ./tmux.conf;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "andrewkim";
      user.email = "andrewykimse@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      nrun = "nix --impure run";
      nshell = "nix --impure shell";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" ];
    };

    initContent = ''
      set -o vi

      autoload -Uz compinit && compinit
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # Cargo
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      export LUAROCKS_DOWNLOADER=curl
    '';
  };
}
