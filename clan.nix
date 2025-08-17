{
  meta.name = "fabrictest";
  meta.description = "tautologicc's darknet";

  inventory.machines.snaz.deploy.targetHost = "root@192.168.100.173";

  inventory.instances.admin = {
    roles.default.tags.all = { };
    roles.default.settings = {
      allowedKeys = {
        "tautologicc@illusions" =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEI496sUFzVECzwdbjWFPwEyGp8tA6OuXKS3qedUXRnF";
        "eff@snaz" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONucbKwW3mhpLJmWpl2Z9oEH13jldnCeopjwn4u4koV";
      };
      certificateSearchDomains = [
        "fabricte.st"
      ];
    };
  };

  inventory.instances.emergency-access = {
    roles.default.tags.nixos = { };
  };
}
