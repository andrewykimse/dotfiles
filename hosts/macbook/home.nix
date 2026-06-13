{ pkgs, ... }:
{
  home.username = "andrewkim";
  home.homeDirectory = "/Users/andrewkim";

  home.packages = with pkgs; [
    aerospace
  ];

  xdg.configFile."aerospace/aerospace.toml".text = ''
    start-at-login = true

    enable-normalization-flatten-containers = true
    enable-normalization-opposite-orientation-for-nested-containers = true

    accordion-padding = 30
    default-root-container-layout = 'tiles'
    default-root-container-orientation = 'auto'

    on-focus-changed = ['move-mouse window-lazy-center']

    [gaps]
    inner.horizontal = 8
    inner.vertical = 8
    outer.left = 8
    outer.right = 8
    outer.top = 8
    outer.bottom = 8

    [mode.main.binding]
    alt-h = 'focus left'
    alt-l = 'focus right'
    alt-j = 'focus down'
    alt-k = 'focus up'

    alt-shift-h = 'move left'
    alt-shift-l = 'move right'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'

    alt-minus = 'resize smart -50'
    alt-equal = 'resize smart +50'

    alt-slash = 'layout tiles horizontal vertical'

    alt-f = 'fullscreen'
    alt-shift-space = 'layout floating tiling'

    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'

    alt-shift-1 = 'move-node-to-workspace 1'
    alt-shift-2 = 'move-node-to-workspace 2'
    alt-shift-3 = 'move-node-to-workspace 3'
    alt-shift-4 = 'move-node-to-workspace 4'
    alt-shift-5 = 'move-node-to-workspace 5'
    alt-shift-6 = 'move-node-to-workspace 6'
    alt-shift-7 = 'move-node-to-workspace 7'
    alt-shift-8 = 'move-node-to-workspace 8'
    alt-shift-9 = 'move-node-to-workspace 9'

    alt-enter = "exec-and-forget osascript -e 'tell application \"Ghostty\" to activate' -e 'delay 0.1' -e 'tell application \"System Events\" to tell process \"Ghostty\" to keystroke \"n\" using command down'"
    alt-q = 'close'

    alt-shift-semicolon = 'mode service'

    [mode.service.binding]
    esc = ['reload-config', 'mode main']
    r = ['flatten-workspace-tree', 'mode main']
    f = ['layout floating tiling', 'mode main']
    backspace = ['close-all-windows-but-current', 'mode main']
    alt-shift-h = ['join-with left', 'mode main']
    alt-shift-j = ['join-with down', 'mode main']
    alt-shift-k = ['join-with up', 'mode main']
    alt-shift-l = ['join-with right', 'mode main']
  '';

  # Remote Nix builder — delegates aarch64-linux builds to the desktop.
  # Desktop must have SSH enabled, andrewkim in trusted-users, and this Mac's
  # SSH key in authorized_keys (see hosts/desktop/configuration.nix).
  home.file.".config/nix/nix.conf".text = ''
    builders = ssh://andrewkim@nixos.local x86_64-linux,aarch64-linux - - big-parallel benchmark nixos-test
    builders-use-substitutes = true
  '';

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
