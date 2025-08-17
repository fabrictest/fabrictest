{ config, ... }:
{
  disko.devices.disk.tank1-disk1 = {
    device = "/dev/disk/by-id/wwn-0x50014ee606173089";
    content.type = "gpt";
    content.partitions.ESP = {
      type = "EF00";
      size = "4G";
      content.type = "filesystem";
      content.format = "vfat";
      content.mountpoint = "/boot";
      content.mountOptions = [ "umask=0077" ];
    };
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank1";
    };
  };

  disko.devices.zpool.tank1 = {
    mode.topology.vdev = [
      {
        members = [ "tank1-disk1" ];
      }
    ];

    options.ashift = "12";
    options.autotrim = "on";

    rootFsOptions.acltype = "posixacl";
    rootFsOptions.atime = "on";
    rootFsOptions.canmount = "off";
    rootFsOptions.checksum = "blake3";
    rootFsOptions.compression = "on";
    rootFsOptions.dnodesize = "auto";
    rootFsOptions.encryption = "on";
    # FIXME(eff): Switch to client certificate authZ. https://github.com/Micinek/zfs-encryption
    rootFsOptions.keyformat = "passphrase";
    rootFsOptions.keylocation = "prompt";
    rootFsOptions.mountpoint = "none";
    rootFsOptions.normalization = "formD";
    rootFsOptions.relatime = "on";
    rootFsOptions.utf8only = "on";
    rootFsOptions.xattr = "sa";
    rootFsOptions."com.sun:auto-snapshot" = "false";
  };

  # ---

  disko.devices.disk.tank2-disk1 = {
    device = "/dev/disk/by-id/wwn-0x5000c500e763eac4";
    content.type = "gpt";
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank2";
    };
  };

  disko.devices.disk.tank2-disk2 = {
    device = "/dev/disk/by-id/wwn-0x5000c500e76ca082";
    content.type = "gpt";
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank2";
    };
  };

  disko.devices.disk.tank2-disk3 = {
    device = "/dev/disk/by-id/wwn-0x5000c500e76cbc61";
    content.type = "gpt";
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank2";
    };
  };

  disko.devices.disk.tank2-cash1 = {
    device = "/dev/disk/by-id/nvme-eui.0000000001000000e4d25c99626e5201";
    content.type = "gpt";
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank2";
    };
  };

  disko.devices.zpool.tank2 = {
    mode.topology.vdev = [
      {
        mode = "raidz1";
        members = [
          "tank2-disk1"
          "tank2-disk2"
          "tank2-disk3"
        ];
      }
    ];
    mode.topology.cache = [ "tank2-cash1" ];

    options.ashift = "12";
    options.autotrim = "on";

    rootFsOptions.acltype = "posixacl";
    rootFsOptions.atime = "on";
    rootFsOptions.canmount = "off";
    rootFsOptions.checksum = "blake3";
    rootFsOptions.compression = "on";
    rootFsOptions.dnodesize = "auto";
    rootFsOptions.encryption = "on";
    # FIXME(eff): Switch to client certificate authZ. https://github.com/Micinek/zfs-encryption
    rootFsOptions.keyformat = "passphrase";
    rootFsOptions.keylocation = "prompt";
    rootFsOptions.mountpoint = "none";
    rootFsOptions.normalization = "formD";
    rootFsOptions.relatime = "on";
    rootFsOptions.utf8only = "on";
    rootFsOptions.xattr = "sa";
    rootFsOptions."com.sun:auto-snapshot" = "false";
  };

  # ---

  # https://b3n.org/zfs-hierarchy/

  # tier1: MUST backup
  # tier2: just persistence between reboots, no backup
  # tier3: temporary, expendable storage, very fast, good for e.g. downloads and video encoding

  disko.devices.zpool.tank1.datasets."dset1".type = "zfs_fs";

  disko.devices.zpool.tank1.datasets."dset1/tier1".type = "zfs_fs";
  disko.devices.zpool.tank1.datasets."dset1/tier2".type = "zfs_fs";
  disko.devices.zpool.tank1.datasets."dset1/tier3".type = "zfs_fs";

  disko.devices.zpool.tank1.datasets."dset1/tier1".options."com.sun:auto-snapshot" = "true";
  disko.devices.zpool.tank1.datasets."dset1/tier3".options.sync = "disabled";

  disko.devices.zpool.tank2.datasets."dset2".type = "zfs_fs";

  disko.devices.zpool.tank2.datasets."dset2/tier1".type = "zfs_fs";
  disko.devices.zpool.tank2.datasets."dset2/tier2".type = "zfs_fs";
  disko.devices.zpool.tank2.datasets."dset2/tier3".type = "zfs_fs";

  disko.devices.zpool.tank2.datasets."dset2/tier1".options."com.sun:auto-snapshot" = "true";
  disko.devices.zpool.tank2.datasets."dset2/tier3".options.sync = "disabled";

  # ---

  # https://grahamc.com/blog/erase-your-darlings/

  disko.devices.zpool.tank1.datasets."dset1/tier2/root" = {
    type = "zfs_fs";
    options.mountpoint = "legacy";
    mountpoint = "/";
    postCreateHook = "zfs snapshot tank1/dset1/tier2/root@blank";
  };

  boot.initrd.systemd.services.zfs-rollback-root = {
    description = "Rollback root filesystem to a pristine state";
    wantedBy = [ "initrd.target" ];
    after = [ "zfs-import-tank1.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    path = [ config.boot.zfs.package ];
    script = "zfs rollback -r tank1/dset1/tier2/root@blank";
  };

  disko.devices.zpool.tank1.datasets."dset1/tier2/nix" = {
    type = "zfs_fs";
    options.mountpoint = "legacy";
    options.atime = "off";
    mountpoint = "/nix";
  };

  disko.devices.zpool.tank1.datasets."dset1/tier1/safe" = {
    # example: dset1/tier1/safe/etc/wireguard, .....
    type = "zfs_fs";
    options.mountpoint = "legacy";
    mountpoint = "/+";
  };

  disko.devices.zpool.tank1.datasets."dset1/tier1/home" = {
    type = "zfs_fs";
    options.mountpoint = "legacy";
    mountpoint = "/home";
  };
}
