{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    # FIXME(eff): Extract 'determinate' clan service.
    inputs.determinate.nixosModules.default
  ];

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
    device = "/persist/var/lib/nixos";
    noCheck = true;
    options = [
      "bind"
    ];
  };

  fileSystems."/var/lib/samba" = {
    device = "/persist/var/lib/samba";
    options = [
      "bind"
      "noauto"
      "x-systemd.automount"
    ];
  };

  systemd.tmpfiles.settings.nas-media."/nas/media".d.mode = "1777";

  services.samba = {
    enable = true;
    openFirewall = true;
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
      };
      media = {
        "comment" = "Media library";
        "create mask" = 0644;
        "directory mask" = 0755;
        "guest ok" = true;
        "path" = "/nas/media";
        "read only" = true;
        "write list" = "@wheel";
      };
    };
  };
}
