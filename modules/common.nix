{ config, lib, pkgs, neovim-config, monkeyterm, viaterm, btop-src, zen-browser ? null, nvidiaLibDir ? null, ... }:
let
  btopPkg = if pkgs.stdenv.isDarwin
    then pkgs.btop.overrideAttrs (old: {
      src = btop-src;
      doInstallCheck = false;
      cmakeFlags = (old.cmakeFlags or []) ++ [ "-DBTOP_GPU=ON" ];
      postInstall = (old.postInstall or "") + ''
        /usr/bin/codesign -s - --entitlements ${pkgs.writeText "btop-entitlements.xml" ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>com.apple.iokit.IOReportUserClient</key>
              <true/>
          </dict>
          </plist>
        ''} --force $out/bin/btop
      '';
    })
    else if nvidiaLibDir != null
    then pkgs.btop.overrideAttrs (old: {
      doInstallCheck = false;
      postFixup = (old.postFixup or "") + ''
        if [ -f "$out/bin/.btop-wrapped" ]; then
          patchelf --add-rpath "${nvidiaLibDir}" "$out/bin/.btop-wrapped"
        else
          patchelf --add-rpath "${nvidiaLibDir}" "$out/bin/btop"
        fi
      '';
    })
    else pkgs.btop;
in
{
  imports = lib.optionals (zen-browser != null) [
    zen-browser.homeModules.beta
  ];

  # home.username and home.homeDirectory are set per-host

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    ripgrep
    fzf
    fd
    fastfetch
    gnumake
    gcc
    jq
    htop
    mpv
    curl
    wget
    btopPkg
    brave
    nix-search-cli
    claude-code
    bottom
    nix-tree
    comma
    neovim-config.packages.${pkgs.system}.default

    # LSP servers
    clang-tools   # clangd for C/C++
    rust-analyzer
    gopls
    zls           # Zig
    nixd          # Nix
    lua-language-server
    pyright
    typescript-language-server
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
    enable = pkgs.stdenv.isLinux;
    installBatSyntax = false;
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

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.bat = {
    enable = true;
    config.theme = "Dracula";
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
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

  programs.gh = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };

  programs.zen-browser = lib.mkIf (pkgs.stdenv.isLinux && zen-browser != null) {
    enable = true;
    policies.ExtensionSettings = let
      mkExt = id: slug: {
        "${id}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    in
      mkExt "uBlock0@raymondhill.net" "ublock-origin" //
      mkExt "vimium-c@gdh1995.cn" "vimium-c";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      nrun = "nix --impure run";
      nshell = "nix --impure shell";
      ff = "fastfetch";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      # theme omitted — starship handles the prompt
    };

    initContent = ''
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
}
