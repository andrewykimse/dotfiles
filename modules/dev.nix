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
    git-spice
    jq
    htop
    mpv
    curl
    wget
    nix-search-cli
    claude-code
    nodejs
    bottom
    nix-tree
    comma
    tree-sitter
    # yazi plugin dependencies
    miller
    glow
    trash-cli
    neovim-config.packages.${pkgs.stdenv.hostPlatform.system}.default

    # image.nvim: provides the MagickWand lib lazy.nvim's hererocks builds
    # the `magick` luarock against, for viewing images in markdown
    imagemagick

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
    ripdrag
    wl-clipboard  # img-clip.nvim: paste clipboard images under Wayland
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pngpaste      # img-clip.nvim: paste clipboard images on macOS
  ] ++ pkgs.lib.optionals (monkeyterm != null) [
    monkeyterm.packages.${pkgs.stdenv.hostPlatform.system}.default
  ] ++ pkgs.lib.optionals (viaterm != null) [
    viaterm.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile."nvim".source = "${neovim-config}/nvim";
}
