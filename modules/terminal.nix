{ pkgs, lib, btop-src, nvidiaLibDir ? null, ... }:
let
  btopPkg = if pkgs.stdenv.isDarwin
    then pkgs.btop.overrideAttrs (old: {
      src = btop-src;
      doInstallCheck = false;
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
    else if nvidiaLibDir != null
    then pkgs.btop.overrideAttrs (old: {
      src = btop-src;
      doInstallCheck = false;
      postFixup = (old.postFixup or "") + ''
        if [ -f "$out/bin/.btop-wrapped" ]; then
          patchelf --add-rpath "${nvidiaLibDir}" "$out/bin/.btop-wrapped"
        else
          patchelf --add-rpath "${nvidiaLibDir}" "$out/bin/btop"
        fi
      '';
    })
    else pkgs.btop;
in
{
  programs.btop = {
    enable = true;
    package = btopPkg;
    settings = {
      color_theme = "dracula";
      theme_background = false;
      truecolor = true;
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty gpu0:0:default cpu:0:default,gpu0:0:default";
      shown_boxes = "cpu mem net proc gpu0";
      update_ms = 100;
      proc_sorting = "cpu lazy";
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_follow_detailed = true;
      show_gpu_info = "On";
      cpu_invert_lower = true;
      cpu_graph_lower = "total";
      vim_keys = true;
      show_uptime = true;
      show_cpu_watts = true;
      check_temp = true;
      show_coretemp = true;
      show_cpu_freq = true;
      show_disks = false;
      io_mode = true;
      io_graph_combined = false;
      net_auto = true;
      net_sync = true;
      show_battery = true;
      show_battery_watts = true;
      nvml_measure_pcie_speeds = true;
      rsmi_measure_pcie_speeds = true;
      gpu_mirror_graph = true;
    };
  };

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
    extraConfig = builtins.readFile ../config/tmux.conf;
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
}
