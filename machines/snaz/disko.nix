{
  disko.devices.disk.tank1-disk1 = {
    type = "disk";
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
    type = "zpool";
    mode.topology.type = "topology";
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

    # https://b3n.org/zfs-hierarchy/

    datasets.ds1.type = "zfs_fs";

    # tier1: MUST backup
    # tier2: just persistence between reboots, no backup
    # tier3: temporary, expendable storage, very fast, good for e.g. downloads and video encoding

    datasets."ds1/tier1" = {
      type = "zfs_fs";
      options."com.sun:auto-snapshot" = "true";
    };
    datasets."ds1/tier2" = {
      type = "zfs_fs";
    };
    datasets."ds1/tier3" = {
      type = "zfs_fs";
      options.sync = "disabled";
    };

    datasets."ds1/tier2/root" = {
      type = "zfs_fs";
      mountpoint = "/";
      options.mountpoint = "legacy";
      # https://grahamc.com/blog/erase-your-darlings/
      postCreateHook = "zfs snapshot tank1/$name@blank";
      postMountHook = "zfs rollback -r tank1/$name@blank";
    };
    datasets."ds1/tier1/root" = {
      type = "zfs_fs";
      mountpoint = "/persist";
      options.mountpoint = "legacy";
    };
    datasets."ds1/tier2/nix" = {
      type = "zfs_fs";
      mountpoint = "/nix";
      options.mountpoint = "legacy";
      options.atime = "off";
    };
    datasets."ds1/tier1/home" = {
      type = "zfs_fs";
      mountpoint = "/home";
      options.mountpoint = "legacy";
    };
  };

  disko.devices.disk.tank2-disk1 = {
    type = "disk";
    device = "/dev/disk/by-id/wwn-0x5000c500e763eac4";
    content.type = "gpt";
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank2";
    };
  };

  disko.devices.disk.tank2-disk2 = {
    type = "disk";
    device = "/dev/disk/by-id/wwn-0x5000c500e76ca082";
    content.type = "gpt";
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank2";
    };
  };

  disko.devices.disk.tank2-disk3 = {
    type = "disk";
    device = "/dev/disk/by-id/wwn-0x5000c500e76cbc61";
    content.type = "gpt";
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank2";
    };
  };

  disko.devices.disk.tank2-cache1 = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-eui.0000000001000000e4d25c99626e5201";
    content.type = "gpt";
    content.partitions.zfs = {
      size = "100%";
      content.type = "zfs";
      content.pool = "tank2";
    };
  };

  disko.devices.zpool.tank2 = {
    type = "zpool";
    mode.topology.type = "topology";
    mode.topology.cache = [
      "tank2-cache1"
    ];
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
    options.ashift = "12";
    options.autotrim = "on";
    rootFsOptions.acltype = "posixacl";
    rootFsOptions.atime = "on";
    rootFsOptions.canmount = "off";
    rootFsOptions.checksum = "blake3";
    rootFsOptions.compression = "on";
    rootFsOptions.dnodesize = "auto";
    rootFsOptions.encryption = "on";
    rootFsOptions.keyformat = "passphrase";
    rootFsOptions.keylocation = "prompt";
    rootFsOptions.mountpoint = "none";
    rootFsOptions.normalization = "formD";
    rootFsOptions.relatime = "on";
    rootFsOptions.utf8only = "on";
    rootFsOptions.xattr = "sa";
    rootFsOptions."com.sun:auto-snapshot" = "false";

    datasets.ds2.type = "zfs_fs";

    datasets."ds2/tier1" = {
      type = "zfs_fs";
      options."com.sun:auto-snapshot" = "true";
    };
    datasets."ds2/tier2" = {
      type = "zfs_fs";
    };
    datasets."ds2/tier3" = {
      type = "zfs_fs";
      options.sync = "disabled";
    };

    datasets."ds2/tier1/nas" = {
      type = "zfs_fs";
      mountpoint = "/nas";
      options.mountpoint = "legacy";
    };
  };
}
