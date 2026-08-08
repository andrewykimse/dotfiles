# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, mt7927-driver, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel: LTS rather than linuxPackages_latest (was 7.0.10) because its PCI
  # allocator does carve the Studio Display's nested Thunderbolt PCIe windows;
  # the display's xHCI gets a valid non-prefetchable BAR here.
  boot.kernelPackages = pkgs.linuxPackages;
  # Thunderbolt PCIe tunneling for the daisy-chained Apple Studio Display, whose
  # USB (camera/speakers/mic) tunnels in behind the CalDigit's deep nested PCIe
  # switch. hpiosize=0: the xHCIs are MMIO-only, so drop the phantom hot-plug I/O
  # window reservations that overflow x86's 64K I/O space and abort bridge config.
  # pcie_port_pm=off: keeps the TB ports from runtime-suspending to D3cold mid-init.
  # pcie_aspm.policy=performance rather than pcie_aspm=off: "off" clears
  # aspm_support_enabled, so the kernel skips the PCIe _OSC handshake entirely
  # ("not requesting OS control; OS requires [ExtendedConfig ASPM ClockPM MSI]")
  # and never gains native hotplug. /sys/bus/pci/slots stays empty, so nothing
  # re-enumerates the display's xHCI after the thunderbolt driver takes the tunnels
  # over from firmware. The policy form pins links in L0 without that side effect.
  boot.kernelParams = [
    "pcie_aspm.policy=performance"
    "pci=realloc"
    "pci=hpiosize=0"
    "pcie_port_pm=off"
  ];
  boot.kernelModules = [ "snd_usb_audio" "k10temp" ];

  hardware.mediatek-mt7927 = {
    enable = true;
    enableWifi = true;
    enableBluetooth = true;
    disableAspm = true;
  };

  # mt7927-nixos installs its modules under lib/modules/<ver>/extra/, but kmod's
  # built-in depmod search string is "updates built-in" and NixOS ships no
  # depmod.d config, so extra/ is never indexed. modprobe therefore keeps
  # resolving the stock in-tree mt7925e, which carries no 7927 PCI ID and never
  # binds. Re-expose the same modules under updates/ so depmod sees them.
  boot.extraModulePackages =
    let
      relocate = pkg: pkgs.runCommand "${pkg.name}-updates" { } ''
        for v in ${pkg}/lib/modules/*; do
          ver=$(basename "$v")
          mkdir -p "$out/lib/modules/$ver/updates"
          cp -r "$v"/extra/* "$out/lib/modules/$ver/updates/"
        done
      '';
    in
    map relocate [
      mt7927-driver.packages.${pkgs.system}.wifi
      mt7927-driver.packages.${pkgs.system}.bluetooth
    ];

  # Same flake, mismatched halves: its firmware package installs the BT blob at
  # mediatek/mt6639/, but its patched btmtk requests mediatek/mt7927/ (the path
  # used by the pending linux-firmware MR), so hci0 fails setup with -2 and
  # retries forever. Alias the blob into the path the driver actually asks for.
  hardware.firmware = [
    (pkgs.runCommand "mt7927-bt-firmware-mt7927-path" { } ''
      mkdir -p "$out/lib/firmware/mediatek/mt7927"
      cp ${mt7927-driver.packages.${pkgs.system}.firmware}/lib/firmware/mediatek/mt6639/BT_RAM_CODE_MT6639_2_1_hdr.bin \
        "$out/lib/firmware/mediatek/mt7927/BT_RAM_CODE_MT6639_2_1_hdr.bin"
    '')
  ];

  networking.hostName = "firelink"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager = {
    enable = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.xone.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    powerManagement.enable = false;
  };

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.hardware.bolt.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.andrewkim = {
    isNormalUser = true;
    description = "Andrew Kim";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    #  thunderbird
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFaIkNIQp0DwxiJo1xU7kD4Fy+R1Phi5S//WIjLN6hwu3//H62lmsW/aTo/fSgWOK+lZgesi4U5IvChGPlcrFUHlZmomWZqtSe5xrCjdJSvMWPioJOm/BXghSUkujLlp0ZlbqgCxMy6y199KpNbNYc91aVY9GhOEXtPZLUNd/LR3h8cVS9grAwdxdNDjA7MLAZFEOeyuQFpSLTeOsUoRyOH2nZ+bFvYtYVGeV7mQJbP6FkwAoIhI6mX7riyxmJuQZOnSzE6TTRKIRnEq1N3T7JG00w6+vWpow6sUYuRJJJjE+qJQxYy0X9ChLVB9+aD1WGCaXXOB+H989CZEg1a+lqKl+7LeiFladw7klNGMED5OpOGMUahDq83D7vd+9uA4ABTbnYUBSgeyr+m9sZV6owbAqsQwnWrA7Ak0iukaYDE4LEmCE6kIq3OPBnODd6lqrYURS5MBAVOkefIEukXMzdT4KEMsZxm5suT8TZtWkAl6O8Po1kLadVZ5QUuEgzXvOPXL4y5i4Vom6mQ4kZpIsFBB4ZtEXzhT6BcafkNqUkceHVRbXVk6AwGaOQtPS78HcWsH3sKJpoIePDV/HNxmpGGuIjBA9yNrK2YzwxKzq9fnej3Zm+xsSdT0PxkX9n5kJi3yEVm/VABmpk06Nq10rPO56lIhM/eOuUaq5adI6DiQ== andrewkim@Andrews-MacBook-Air-2.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBhbjTEGraaqwvy8uRaFRdxkUwiiufzkVYdf8DYpuzha root@Andrews-Macbook-Pro"
    ];
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  # Apptainer for containerized HPC workloads (OpenFOAM — not packageable in
  # nixpkgs due to its wmake build system; OpenCFD ships official images).
  # Runs unprivileged via user namespaces, binds $HOME by default.
  programs.singularity = {
    enable = true;
    package = pkgs.apptainer;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Hyprland (Wayland compositor). GDM exposes it as a session option at login.
  programs.hyprland.enable = true;

  # Creates bwrap SUID wrapper in /run/wrappers/bin/bwrap, required for
  # Steam's instance IPC (steam-runtime-steam-remote) to work.
  programs.steam.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      wget
      pciutils
      lshw
      lm_sensors
      moonlight-qt
  ];

  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true; # required for DRM/KMS capture on Wayland
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  services.tailscale.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # Allow this machine to build aarch64 packages via QEMU emulation.
  # Required for `nix build .#packages.aarch64-linux.roundtable-sd-image`.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  system.stateVersion = "25.11"; # Did you read the comment?
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "andrewkim" ];

}
