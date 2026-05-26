{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "roundtable";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  # mDNS — makes roundtable.local resolvable on the LAN
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      workstation = true;
    };
  };

  # ---------------------------------------------------------------------------
  # ZFS
  # ---------------------------------------------------------------------------

  services.zfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 4;   # 15-min snapshots, keep 4
    hourly   = 24;
    daily    = 7;
    weekly   = 4;
    monthly  = 12;
  };

  # ---------------------------------------------------------------------------
  # SSH
  # ---------------------------------------------------------------------------

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ---------------------------------------------------------------------------
  # Samba (SMB file sharing — Windows, macOS, Linux)
  # ---------------------------------------------------------------------------

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup         = "WORKGROUP";
        "server string"   = "roundtable";
        "server role"     = "standalone server";
        security          = "user";
        "map to guest"    = "Never";
        logging           = "systemd";
        # macOS compatibility
        "vfs objects"     = "catia fruit streams_xattr";
        "fruit:metadata"  = "stream";
        "fruit:model"     = "MacSamba";
      };

      shares = {
        path             = "/storage/shares";
        browseable       = "yes";
        "read only"      = "no";
        "guest ok"       = "no";
        "create mask"    = "0664";
        "directory mask" = "0775";
        "valid users"    = "@storage";
        "force group"    = "storage";
      };

      backups = {
        path             = "/storage/backups";
        browseable       = "yes";
        "read only"      = "no";
        "guest ok"       = "no";
        "create mask"    = "0664";
        "directory mask" = "0775";
        "valid users"    = "@storage";
        "force group"    = "storage";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # NFS (Linux clients)
  # Adjust the subnet to match your LAN (e.g. 10.0.0.0/24).
  # ---------------------------------------------------------------------------

  services.nfs.server = {
    enable = true;
    exports = ''
      /storage/shares  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
      /storage/backups 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  # ---------------------------------------------------------------------------
  # MinIO (S3-compatible object storage)
  #
  # Before starting MinIO, create /etc/minio-credentials:
  #   MINIO_ROOT_USER=<your-admin-user>
  #   MINIO_ROOT_PASSWORD=<strong-password-min-8-chars>
  # Then: chmod 600 /etc/minio-credentials
  # ---------------------------------------------------------------------------

  services.minio = {
    enable = true;
    dataDir = [ "/storage/minio" ];
    listenAddress = "0.0.0.0:9000";
    consoleAddress = "0.0.0.0:9001";
    rootCredentialsFile = "/etc/minio-credentials";
  };

  # ---------------------------------------------------------------------------
  # Tailscale (secure remote access)
  # After boot: tailscale up --advertise-exit-node (or just tailscale up)
  # ---------------------------------------------------------------------------

  services.tailscale.enable = true;

  # ---------------------------------------------------------------------------
  # Monitoring
  # ---------------------------------------------------------------------------

  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = false;  # only reachable via Tailscale / LAN tools
    port = 9100;
    enabledCollectors = [ "systemd" "zfs" ];
  };

  # ---------------------------------------------------------------------------
  # Firewall
  # ---------------------------------------------------------------------------

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH
      2049  # NFS
      9000  # MinIO API
      9001  # MinIO console
    ];
    allowedUDPPorts = [
      2049  # NFS
    ];
    # Tailscale and Samba open their own rules via openFirewall = true
    trustedInterfaces = [ "tailscale0" ];
  };

  # ---------------------------------------------------------------------------
  # Users
  # ---------------------------------------------------------------------------

  users.groups.storage = { };

  users.users.andrewkim = {
    isNormalUser = true;
    description  = "Andrew Kim";
    extraGroups  = [ "wheel" "storage" "networkmanager" ];
    shell        = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # paste your ~/.ssh/id_*.pub here
    ];
  };

  programs.zsh.enable = true;

  # Ensure mount-point directories and correct ownership survive reboots.
  # ZFS mounts happen before tmpfiles, so this is safe — tmpfiles only
  # adjusts permissions on the already-mounted dataset.
  systemd.tmpfiles.rules = [
    "d /storage/shares  0775 andrewkim storage -"
    "d /storage/backups 0775 andrewkim storage -"
    "d /storage/minio   0750 minio      minio   -"
  ];

  # ---------------------------------------------------------------------------
  # Packages
  # ---------------------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    vim
    htop
    iotop           # per-process I/O usage
    smartmontools   # smartctl — drive health
    hdparm          # drive parameters / spin-down
    parted
    rsync
    tmux
    lsof
    curl
    wget
    pciutils        # lspci — useful for HAT/PCIe debugging
    usbutils        # lsusb
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
