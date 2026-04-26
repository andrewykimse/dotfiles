{ config, pkgs, ... }:
{
  home.username = "andrewkim";
  home.homeDirectory = if pkgs.stdenv.isDarwin
    then "/Users/andrewkim"
    else "/home/andrewkim";

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    htop
    curl
    wget
  ];

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
      autoload -Uz compinit && compinit
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # Cargo
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      export LUAROCKS_DOWNLOADER=curl
    '';
  };
}
