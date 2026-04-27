{ pkgs, ... }:
{
  home.username = "andrewkim";
  home.homeDirectory = "/home/andrewkim";

  # NixOS desktop-specific packages
  home.packages = with pkgs; [
    # add linux-only tools here
  ];
}
