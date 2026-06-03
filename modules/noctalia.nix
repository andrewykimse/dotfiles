{ noctalia, ... }:
{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
  };

  wayland.windowManager.hyprland.settings.exec-once = [
    "noctalia-shell"
  ];
}
