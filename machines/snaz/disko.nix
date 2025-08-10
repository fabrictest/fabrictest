# ---
# schema = "single-disk"
# [placeholders]
# mainDisk = "/dev/disk/by-id/ata-WDC_WD10JPVX-22JC3T0_WD-WX21A9519AN2" 
# ---
# This file was automatically generated!
# CHANGING this configuration requires wiping and reinstalling the machine
{

  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = true;
  disko.devices = {
    disk = {
      main = {
        name = "main-9b1a2bcb7c4b4975b9725dd3ef27afdf";
        device = "/dev/disk/by-id/ata-WDC_WD10JPVX-22JC3T0_WD-WX21A9519AN2";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            "boot" = {
              size = "1M";
              type = "EF02"; # for grub MBR
              priority = 1;
            };
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
