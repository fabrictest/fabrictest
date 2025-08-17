{ config, lib, ... }:
{
  clan.core.settings.state-version.enable = true;

  clan.core.settings.machine-id.enable = true;
  networking.hostId = lib.substring 0 8 config.clan.core.settings.machine-id.files.machineId.value;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  networking.domain = "fabricte.st";

  services.zfs.autoSnapshot.flags = "-k -p --utc";

  fileSystems."/var/lib/nixos" = {
    device = "/+/var/lib/nixos";
    noCheck = true;
    options = [ "bind" ];
  };
}
