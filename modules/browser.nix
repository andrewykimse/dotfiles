{ pkgs, lib, zen-browser ? null, ... }:
{
  imports = lib.optionals (zen-browser != null) [
    zen-browser.homeModules.beta
  ];

  home.packages = with pkgs; [ brave ];

  # Allow unfree for nix-shell / nix-env (channel commands)
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  # Allow unfree for flake commands (nix run/shell) — still needs --impure
  home.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";

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
}
