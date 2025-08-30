{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  clan.core.settings.state-version.enable = true;

  networking.domain = "fabricte.st";

  clan.core.settings.machine-id.enable = true;

  networking.hostId =
    lib.substring 0 8
      config.clan.core.vars.generators.machine-id.files.machineId.value;

  networking.useNetworkd = true;

  time.timeZone = "UTC";

  fileSystems."/var/lib/nixos" = {
    device = "/safe/var/lib/nixos";
    noCheck = true;
    options = [
      "bind"
    ];
  };

  fileSystems."/var/lib/samba" = {
    device = "/safe/var/lib/samba";
    options = [
      "bind"
      "noauto"
      "x-systemd.automount"
    ];
  };

  services.samba = {
    enable = true;
    package = pkgs.samba4Full;
    openFirewall = true;
    usershares.enable = true;
    settings = {
      global = {
        # TODO(eff): Set "ftp" user as guest account instead of "nobody".
        "guest account" = "nobody";
        "hosts allow" = "192.168.0. 192.168.100. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "map to guest" = "Bad User";
        "security" = "user";
        "server role" = "standalone";
        "server smb encrypt" = "required";
        "use sendfile" = true;
        "create mask" = 0664;
        "directory mask" = 2755;
        "force create mode" = 0644;
        "force directory mode" = 2755;
        "server min protocol" = "SMB3";
      };
    };
  };
}
