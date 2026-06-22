{ pkgs, lib, zen-browser ? null, helium-browser ? null, ... }:
{
  imports =
    lib.optionals (zen-browser != null) [
      zen-browser.homeModules.beta
    ] ++
    lib.optionals (helium-browser != null) [
      helium-browser.homeModules.default
    ];

  home.packages = with pkgs; [ brave ];

  programs.helium = lib.mkIf (pkgs.stdenv.isLinux && helium-browser != null) {
    enable = true;
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
}
