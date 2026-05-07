{ config, pkgs, neovim-config, monkeyterm, viaterm, btop-src, ... }:
let
  btopPkg = if pkgs.stdenv.isDarwin
    then pkgs.btop.overrideAttrs (old: {
      src = btop-src;
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
    else let
      nvml-lib = pkgs.runCommand "nvml-lib" {} ''
        mkdir -p $out/lib
        ln -s /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 $out/lib/libnvidia-ml.so.1
        ln -s libnvidia-ml.so.1 $out/lib/libnvidia-ml.so
      '';
    in pkgs.btop.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/btop \
          --prefix LD_LIBRARY_PATH : "${nvml-lib}/lib"
      '';
    });
in
{
  # home.username and home.homeDirectory are set per-host

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fzf
    fd
    gnumake
    gcc
    jq
    htop
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
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };
    settings = {
      user.name = "andrewkim";
      user.email = "andrewykimse@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
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
    '';
  };
}
