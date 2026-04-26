{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # mac-only tools
  ];

  programs.zsh = {
    shellAliases = {
      brew86 = "arch -x86_64 /usr/local/Homebrew/bin/brew";
      icat = "kitty +kitten icat --align left";
    };

    initContent = ''
      # PATH additions
      export PATH="/opt/homebrew/opt/icu4c@77/bin:$PATH"
      export PATH="/opt/homebrew/opt/icu4c@77/sbin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"

      # Conda
      __conda_setup="$('/Users/andrewkim/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
      if [ $? -eq 0 ]; then
          eval "$__conda_setup"
      else
          if [ -f "/Users/andrewkim/miniconda3/etc/profile.d/conda.sh" ]; then
              . "/Users/andrewkim/miniconda3/etc/profile.d/conda.sh"
          else
              export PATH="/Users/andrewkim/miniconda3/bin:$PATH"
          fi
      fi
      unset __conda_setup
    '';
  };
}
