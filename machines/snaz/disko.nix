{
  config,
  pkgs,
  ...
}:
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
    mode.topology = {
      type = "topology";
      vdev = [
        {
          members = [ "tank1-disk1" ];
        }
      ];
    };
    options = {
      ashift = "12";
      autotrim = "on";
    };
    rootFsOptions = {
      acltype = "posixacl";
      atime = "on";
      canmount = "off";
      checksum = "blake3";
      compression = "on";
      dnodesize = "auto";
      encryption = "on";
      # FIXME(eff): Switch to client certificate authZ. https://github.com/Micinek/zfs-encryption
      keyformat = "passphrase";
      keylocation = "file://${config.clan.core.vars.generators."zfs.tank1".files.passphrase.path}";
      mountpoint = "none";
      normalization = "formD";
      relatime = "on";
      utf8only = "on";
      xattr = "sa";
      "com.sun:auto-snapshot" = "false";
    };
  };

  clan.core.vars.generators."zfs.tank1" = {
    files.passphrase.deploy = false;
    prompts.passphrase.type = "hidden";
    prompts.passphrase.persist = true;
    prompts.passphrase.description = "Leave empty to generate automatically";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.xkcdpass
    ];
    script = ''
      tr -d '\n' <"$prompts"/passphrase >"$out"/passphrase
      test -s "$out"/passphrase ||
        xkcdpass --numwords 3 --delimiter - --count 1 | tr -d '\n' >"$out"/passphrase
    '';
  };

  # ---

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
    mode.topology = {
      type = "topology";
      cache = [ "tank2-cache1" ];
      vdev = [
        {
          mode = "raidz1";
          members = [
            "tank2-disk1"
            "tank2-disk2"
            "tank2-disk3"
          ];
        }
      ];
    };
    options = {
      ashift = "12";
      autotrim = "on";
    };
    rootFsOptions = {
      acltype = "posixacl";
      atime = "on";
      canmount = "off";
      checksum = "blake3";
      compression = "on";
      dnodesize = "auto";
      encryption = "on";
      keyformat = "hex";
      keylocation = "file://${config.clan.core.vars.generators."zfs.tank2".files.keyfile.path}";
      mountpoint = "none";
      normalization = "formD";
      relatime = "on";
      utf8only = "on";
      xattr = "sa";
      "com.sun:auto-snapshot" = "false";
    };
  };

  clan.core.vars.generators."zfs.tank2" = {
    files.keyfile.neededFor = "partitioning";
    runtimeInputs = [ pkgs.coreutils ];
    script = ''
      od -x -An -N32 -w64 /dev/urandom | tr -d '[:blank:]' >"$out/keyfile"
    '';
  };

  # ---

  # https://b3n.org/zfs-hierarchy/

  # tier1: MUST backup
  # tier2: just persistence between reboots, no backup
  # tier3: temporary, expendable storage, very fast, good for e.g. downloads and video encoding

  disko.devices.zpool.tank1.datasets."ds1".type = "zfs_fs";
  disko.devices.zpool.tank1.datasets."ds1/tier1".type = "zfs_fs";
  disko.devices.zpool.tank1.datasets."ds1/tier1".options."com.sun:auto-snapshot" = "true";
  disko.devices.zpool.tank1.datasets."ds1/tier2".type = "zfs_fs";
  disko.devices.zpool.tank1.datasets."ds1/tier3".type = "zfs_fs";
  disko.devices.zpool.tank1.datasets."ds1/tier3".options.sync = "disabled";

  disko.devices.zpool.tank2.datasets."ds2".type = "zfs_fs";
  disko.devices.zpool.tank2.datasets."ds2/tier1".type = "zfs_fs";
  disko.devices.zpool.tank2.datasets."ds2/tier1".options."com.sun:auto-snapshot" = "true";
  disko.devices.zpool.tank2.datasets."ds2/tier2".type = "zfs_fs";
  disko.devices.zpool.tank2.datasets."ds2/tier3".type = "zfs_fs";
  disko.devices.zpool.tank2.datasets."ds2/tier3".options.sync = "disabled";

  # ---

  # https://grahamc.com/blog/erase-your-darlings/

  disko.devices.zpool.tank1.datasets."ds1/tier2/root" = {
    type = "zfs_fs";
    options.mountpoint = "legacy";
    mountpoint = "/";
    postCreateHook = "zfs snapshot tank1/ds1/tier2/root@blank";
  };

  boot.initrd.systemd.services.zfs-rollback-root = {
    description = "Rollback root filesystem to a pristine state";
    wantedBy = [ "initrd.target" ];
    after = [ "zfs-import-tank1.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    path = [ config.boot.zfs.package ];
    script = "zfs rollback -r tank1/ds1/tier2/root@blank";
  };

  disko.devices.zpool.tank1.datasets."ds1/tier2/nix" = {
    type = "zfs_fs";
    options.mountpoint = "legacy";
    options.atime = "off";
    mountpoint = "/nix";
  };

  disko.devices.zpool.tank1.datasets."ds1/tier1/safe" = {
    # example: /etc/wireguard -> /+/etc/wireguard, .....
    type = "zfs_fs";
    options.mountpoint = "legacy";
    mountpoint = "/+";
  };

  disko.devices.zpool.tank1.datasets."ds1/tier1/home" = {
    type = "zfs_fs";
    options.mountpoint = "legacy";
    mountpoint = "/home";
  };

  disko.devices.zpool.tank2.datasets."ds2/tier1/media" = {
    type = "zfs_fs";
    options.sharesmb = "on";
  };
}
