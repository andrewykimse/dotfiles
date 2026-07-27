{ pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      nrun = "nix --impure run";
      nshell = "nix --impure shell";
      ff = "fastfetch";
      ga = "git add";
      gcm = "git commit -m";
      gg = "git status";
      gs = "git stash";
      gp = "git pull";
      gP = "git push";
      mail = "aerc";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
      append = true;
    };

    initContent = ''
      [[ ":$PATH:" != *":$HOME/.nix-profile/bin:"* ]] && export PATH="$HOME/.nix-profile/bin:$PATH"

      # Volta (Node version manager)
      export VOLTA_HOME="$HOME/.volta"
      [[ ":$PATH:" != *":$VOLTA_HOME/bin:"* ]] && export PATH="$VOLTA_HOME/bin:$PATH"

      set -o vi

      autoload -Uz compinit && compinit
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # Cargo
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      export LUAROCKS_DOWNLOADER=curl

      # Per-branch tmux sessions
      # Usage: tms [session-name]
      #   No args: uses repo/branch as session name
      #   With arg: uses the provided name
      tms() {
        local name
        if [ -n "$1" ]; then
          name="$1"
        else
          local repo branch
          repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
          branch=$(git branch --show-current 2>/dev/null)
          if [ -z "$repo" ] || [ -z "$branch" ]; then
            echo "Not in a git repo and no session name provided"
            return 1
          fi
          name="''${repo}@''${branch}"
        fi
        name=$(echo "$name" | tr '.' '-')
        if [ -n "$TMUX" ]; then
          if ! tmux has-session -t="$name" 2>/dev/null; then
            tmux new-session -ds "$name" -c "$(pwd)"
          fi
          tmux switch-client -t "$name"
        else
          tmux new-session -As "$name" -c "$(pwd)"
        fi
      }
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      aws.disabled = true;
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
