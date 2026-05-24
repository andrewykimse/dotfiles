{ pkgs, lib, neovim-config, monkeyterm, viaterm, ... }:
{
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
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    usbutils
  ] ++ pkgs.lib.optionals (monkeyterm != null) [
    monkeyterm.packages.${pkgs.system}.default
  ] ++ pkgs.lib.optionals (viaterm != null) [
    viaterm.packages.${pkgs.system}.default
  ];

  xdg.configFile."nvim".source = "${neovim-config}/nvim";
}
