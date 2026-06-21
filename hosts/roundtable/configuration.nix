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
  # Garage (S3-compatible object storage — lightweight Rust alternative to MinIO)
  #
  # Before starting Garage, create /etc/garage-secrets:
  #   GARAGE_RPC_SECRET=$(openssl rand -hex 32)
  # Then: chmod 600 /etc/garage-secrets
  #
  # After first start, initialize the cluster layout (single-node):
  #   garage node id                              # get the node ID
  #   garage layout assign -z dc1 -c 1T <id>     # assign zone + capacity
  #   garage layout apply --version 1
  #   garage bucket create <bucket-name>
  #   garage key create <key-name>
  #   garage bucket allow --read --write --owner <bucket> --key <key>
  # ---------------------------------------------------------------------------

  services.garage = {
    enable = true;
    package = pkgs.garage;
    environmentFile = "/etc/garage-secrets";
    settings = {
      metadata_dir    = "/storage/garage/meta";
      data_dir        = "/storage/garage/data";
      replication_factor = 1;
      rpc_bind_addr   = "[::]:3901";
      s3_api = {
        s3_region    = "garage";
        api_bind_addr = "[::]:3900";
      };
      admin = {
        api_bind_addr = "127.0.0.1:3903";
      };
    };
  };

  # DynamicUser (the module default) can't write to a custom ZFS path;
  # use a dedicated static user with ReadWritePaths set by the module.
  users.users.garage = {
    isSystemUser = true;
    group = "garage";
  };
  users.groups.garage = { };

  systemd.services.garage.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User        = lib.mkForce "garage";
    Group       = lib.mkForce "garage";
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
      3900  # Garage S3 API
      # 3901 RPC is cluster-internal; 3903 admin is localhost-only
      80    # Nextcloud
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
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFaIkNIQp0DwxiJo1xU7kD4Fy+R1Phi5S//WIjLN6hwu3//H62lmsW/aTo/fSgWOK+lZgesi4U5IvChGPlcrFUHlZmomWZqtSe5xrCjdJSvMWPioJOm/BXghSUkujLlp0ZlbqgCxMy6y199KpNbNYc91aVY9GhOEXtPZLUNd/LR3h8cVS9grAwdxdNDjA7MLAZFEOeyuQFpSLTeOsUoRyOH2nZ+bFvYtYVGeV7mQJbP6FkwAoIhI6mX7riyxmJuQZOnSzE6TTRKIRnEq1N3T7JG00w6+vWpow6sUYuRJJJjE+qJQxYy0X9ChLVB9+aD1WGCaXXOB+H989CZEg1a+lqKl+7LeiFladw7klNGMED5OpOGMUahDq83D7vd+9uA4ABTbnYUBSgeyr+m9sZV6owbAqsQwnWrA7Ak0iukaYDE4LEmCE6kIq3OPBnODd6lqrYURS5MBAVOkefIEukXMzdT4KEMsZxm5suT8TZtWkAl6O8Po1kLadVZ5QUuEgzXvOPXL4y5i4Vom6mQ4kZpIsFBB4ZtEXzhT6BcafkNqUkceHVRbXVk6AwGaOQtPS78HcWsH3sKJpoIePDV/HNxmpGGuIjBA9yNrK2YzwxKzq9fnej3Zm+xsSdT0PxkX9n5kJi3yEVm/VABmpk06Nq10rPO56lIhM/eOuUaq5adI6DiQ== andrewkim@Andrews-MacBook-Air-2.local"
    ];
  };

  programs.zsh.enable = true;

  # Ensure mount-point directories and correct ownership survive reboots.
  # ZFS mounts happen before tmpfiles, so this is safe — tmpfiles only
  # adjusts permissions on the already-mounted dataset.
  systemd.tmpfiles.rules = [
    "d /storage/shares       0775 andrewkim storage -"
    "d /storage/backups      0775 andrewkim storage -"
    "d /storage/garage       0750 garage    garage  -"
    "d /storage/garage/meta  0750 garage    garage  -"
    "d /storage/garage/data  0750 garage    garage  -"
    "d /storage/nextcloud    0750 nextcloud nextcloud -"
  ];

  # ---------------------------------------------------------------------------
  # Nextcloud
  #
  # Before first deploy, create the admin password file on the machine:
  #   echo -n 'your-password' | sudo tee /etc/nextcloud-admin-pass
  #   sudo chmod 600 /etc/nextcloud-admin-pass
  #
  # Access at http://roundtable.local after deploying.
  # ---------------------------------------------------------------------------

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [{
      name = "nextcloud";
      ensureDBOwnership = true;
    }];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "roundtable.local";
    https = false;
    home = "/storage/nextcloud";

    config = {
      dbtype = "pgsql";
      dbhost = "/run/postgresql";  # Unix socket — peer auth, no password needed
      adminpassFile = "/etc/nextcloud-admin-pass";
    };

    settings = {
      trusted_domains = [
        "roundtable.local"
        "192.168.68.0/24"
      ];
      default_phone_region = "US";
    };
  };

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
