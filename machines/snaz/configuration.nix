{
  clan = {
    core = {
      networking = {
        # targetHost = "root@snaz";
      };
    };
  };

  users = {
    users = {
      root = {
        openssh = {
          authorizedKeys = {
            keys = [
              # TODO(eff): Decommission SSH key once we get into Bitwarden.
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEI496sUFzVECzwdbjWFPwEyGp8tA6OuXKS3qedUXRnF" # tautologicc@illusions

              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONucbKwW3mhpLJmWpl2Z9oEH13jldnCeopjwn4u4koV" # eff@snaz
            ];
          };
        };
      };
    };
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  services = {
    displayManager = {
      gdm = {
        enable = true;
      };
    };

    desktopManager = {
      gnome = {
        enable = true;
      };
    };
  };
}
