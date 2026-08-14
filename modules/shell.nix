{ pkgs, lib, pyroclear-src, ... }:
{
  home.packages = [
    ((pkgs.callPackage "${pyroclear-src}/package.nix" { }).overrideAttrs (old: {
      meta = old.meta // { platforms = lib.platforms.unix; };
    }))
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      clear = "pyroclear";
      nrun = "nix --impure run";
      nshell = "nix --impure shell";
      ff = "fastfetch";
      ga = "git add";
      gb = "git branch";
      gcm = "git commit -m";
      gch = "git checkout";
      gg = "git status";
      gs = "git stash";
      gp = "git pull";
      gP = "git push";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
      append = true;
    };

    initContent = ''
      # Tag this shell (and everything it spawns) with the workspace it was
      # opened on. Ghostty is single-instance, so every tab/window shares
      # one pid to Hyprland -- hyprland.lua can't tell tabs apart by pid
      # alone, and "last focused" drifts to whatever tab you're currently
      # typing in. This is set once per shell (the +x check leaves it alone,
      # even if empty, for every subshell/tmux pane so it can't drift to
      # wherever a later command happens to run) and is read directly out of
      # a spawned process's environment, sidestepping the pid ambiguity.
      if [[ -z "''${HYPR_SPAWN_WORKSPACE+x}" ]]; then
        export HYPR_SPAWN_WORKSPACE=""
        if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
          HYPR_SPAWN_WORKSPACE=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty')
        fi
      fi

      [[ ":$PATH:" != *":$HOME/.nix-profile/bin:"* ]] && export PATH="$HOME/.nix-profile/bin:$PATH"

      # Volta (Node version manager)
      export VOLTA_HOME="$HOME/.volta"
      [[ ":$PATH:" != *":$VOLTA_HOME/bin:"* ]] && export PATH="$VOLTA_HOME/bin:$PATH"

      set -o vi

      autoload -Uz compinit && compinit
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      bindkey '  ' autosuggest-accept
      bindkey '^ ' autosuggest-execute

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
