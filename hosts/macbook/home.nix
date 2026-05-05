{ pkgs, ... }:
{
  home.username = "andrewkim";
  home.homeDirectory = "/Users/andrewkim";

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

    '';
  };
}
