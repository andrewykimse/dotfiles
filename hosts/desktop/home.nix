{ pkgs, ... }:
{
  # NixOS desktop-specific packages
  home.packages = with pkgs; [
    # add linux-only tools here
  ];
}
