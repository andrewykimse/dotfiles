{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ZFS requires a unique 8-char hex host identifier per machine.
  # Never share this value across machines that could see the same pool.
  networking.hostId = "28d00896";

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  # Import the storage pool on boot (pool must already exist — see creation
  # commands below). NixOS will not create the pool; it only imports it.
  boot.zfs.extraPools = [ "tank" ];

  # Cap ZFS ARC at 2 GiB on the 8 GB Pi 5, leaving headroom for Samba/MinIO.
  boot.extraModprobeConfig = ''
    options zfs zfs_arc_max=2147483648
  '';

  # Root filesystem lives on the SD card / USB boot device.
  # Run `lsblk -o NAME,LABEL,FSTYPE` after first boot to confirm labels;
  # the NixOS aarch64 SD image typically uses NIXOS_SD and BOOT.
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # ---------------------------------------------------------------------------
  # ONE-TIME ZFS POOL SETUP (run manually after first boot)
  # ---------------------------------------------------------------------------
  #
  # 1. Identify drives by stable ID (never use /dev/sdX directly with ZFS):
  #      ls -la /dev/disk/by-id/ | grep -v part
  #
  # 2. Create the RAIDZ1 pool (~3 TiB usable, 1-drive fault tolerance):
  #      zpool create -o ashift=12 \
  #        -O compression=lz4 \
  #        -O atime=off \
  #        -O xattr=sa \
  #        -O dnodesize=auto \
  #        tank raidz1 \
  #          /dev/disk/by-id/DRIVE1 \
  #          /dev/disk/by-id/DRIVE2 \
  #          /dev/disk/by-id/DRIVE3 \
  #          /dev/disk/by-id/DRIVE4
  #
  # 3. Create datasets with per-dataset tuning:
  #      zfs create -o mountpoint=/storage/shares tank/shares
  #      zfs create -o mountpoint=/storage/backups -o recordsize=1M -o compression=zstd tank/backups
  #      zfs create -o mountpoint=/storage/minio   -o recordsize=1M tank/minio
  #
  # 4. Set snapshot flags (MinIO manages its own data integrity, skip it there):
  #      zfs set com.sun:auto-snapshot=true  tank/shares
  #      zfs set com.sun:auto-snapshot=true  tank/backups
  #      zfs set com.sun:auto-snapshot=false tank/minio
  #
  # 5. Fix ownership so services can write:
  #      chown -R andrewkim:storage /storage/shares /storage/backups
  #      chown -R minio:minio /storage/minio
  # ---------------------------------------------------------------------------
}
