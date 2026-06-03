{ noctalia, ... }:
{
  imports = [ noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    settings = {
      appLauncher = {
        enableClipboardHistory = true;
        autoPasteClipboard = true;
      };
    };
  };

  wayland.windowManager.hyprland.settings.exec-once = [
    "noctalia-shell"
  ];
}
