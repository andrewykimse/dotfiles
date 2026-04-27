{ pkgs, ... }:
{
  home.username = "akim7";
  home.homeDirectory = "/home/akim7";

  # Work machine packages
  home.packages = with pkgs; [
    # add work-specific tools here
  ];
}
