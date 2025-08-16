{ config, ... }:
{
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      systemd-boot = {
        enable = true;
        editor = false;
      };
    };
    initrd = {
      systemd = {
        enable = true;
        services = {
          zfs-rollback-root = {
            description = "Rollback the root filesystem to a pristine state on boot";
            wantedBy = [
              "initrd.target"
            ];
            after = [
              "zfs-import-tank1.service"
            ];
            before = [
              "sysroot.mount"
            ];
            unitConfig = {
              DefaultDependencies = "no";
            };
            serviceConfig = {
              Type = "oneshot";
            };
            path = [ config.boot.zfs.package ];
            script = "zfs rollback -r tank1/dset1/tier2/root@blank";
          };
        };
      };
    };
  };

  disko = {
    devices = {
      disk = {
        tank1-disk1 = {
          type = "disk";
          device = "/dev/disk/by-id/ata-WDC_WD10JPVX-22JC3T0_WD-WX21A9519AN2";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "4G";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "umask=0077"
                  ];
                };
              };
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "tank1";
                };
              };
            };
          };
        };
        tank2-disk1 = {
          type = "disk";
          device = "/dev/disk/by-id/ata-ST16000NM002J-2TW133_ZR70YD88";
          content = {
            type = "gpt";
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "tank2";
                };
              };
            };
          };
        };
        tank2-disk2 = {
          type = "disk";
          device = "/dev/disk/by-id/ata-ST16000NM002J-2TW133_ZRS0GZK9";
          content = {
            type = "gpt";
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "tank2";
                };
              };
            };
          };
        };
        tank2-disk3 = {
          type = "disk";
          device = "/dev/disk/by-id/ata-ST16000NM002J-2TW133_ZRS0JX3C";
          content = {
            type = "gpt";
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "tank2";
                };
              };
            };
          };
        };
        tank2-cash1 = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-INTEL_HBRPEKNX0202A_PHTE030001VT512B-1";
          content = {
            type = "gpt";
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "tank2";
                };
              };
            };
          };
        };
      };
      zpool = {
        tank1 = {
          type = "zpool";
          mode = {
            topology = {
              type = "topology";
              vdev = [
                {
                  members = [ "tank1-disk1" ];
                }
              ];
            };
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
            keylocation = "prompt";
            mountpoint = "none";
            normalization = "formD";
            relatime = "on";
            utf8only = "on";
            xattr = "sa";
            "com.sun:auto-snapshot" = "false";
          };
          datasets = {
            # TODO(eff): Create dataset `reserved` with reserved space.
            "dset1" = {
              type = "zfs_fs";
              options = {
                mountpoint = "none";
              };
            };
            "dset1/tier1" = {
              # MUST backup
              type = "zfs_fs";
              options = {
                "com.sun:auto-snapshot" = "true";
              };
            };
            "dset1/tier1/user" = {
              type = "zfs_fs";
              options = {
                mountpoint = "legacy";
              };
              mountpoint = "/home";
            };
            "dset1/tier1/host" = {
              # example: dset1/tier1/host/wg, .....
              type = "zfs_fs";
              options = {
                mountpoint = "legacy";
              };
              mountpoint = "/_";
            };
            "dset1/tier2" = {
              # just persistence between reboots, no backup
              type = "zfs_fs";
            };
            "dset1/tier2/root" = {
              type = "zfs_fs";
              options = {
                mountpoint = "legacy";
              };
              mountpoint = "/";
              postCreateHook = "zfs snapshot tank1/dset1/tier2/root@blank";
            };
            "dset1/tier2/nix" = {
              type = "zfs_fs";
              options = {
                atime = "off";
                mountpoint = "legacy";
                relatime = "off";
              };
              mountpoint = "/nix";
            };
            "dset1/tier3" = {
              # temporary, expendable storage, very fast
              # good for e.g. downloads and video encoding
              type = "zfs_fs";
              options = {
                sync = "disabled";
              };
            };
          };
        };
        tank2 = {
          type = "zpool";
          mode = {
            topology = {
              type = "topology";
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
              cache = [
                "tank2-cash1"
              ];
            };
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
            keylocation = "prompt";
            mountpoint = "none";
            normalization = "formD";
            relatime = "on";
            utf8only = "on";
            xattr = "sa";
            "com.sun:auto-snapshot" = "false";
          };
          datasets = {
            "dset2" = {
              type = "zfs_fs";
              options = {
                mountpoint = "none";
              };
            };
            "dset2/tier1" = {
              # MUST backup
              type = "zfs_fs";
              options = {
                "com.sun:auto-snapshot" = "true";
              };
            };
            "dset2/tier2" = {
              # just persistence between reboots, no backup
              type = "zfs_fs";
            };
            "dset2/tier3" = {
              # temporary, expendable storage, very fast
              type = "zfs_fs";
              options = {
                sync = "disabled";
              };
            };
          };
        };
      };
    };
  };
}
