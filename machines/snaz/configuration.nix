{
  system.stateVersion = "25.11";

  users.users.root.openssh.authorizedKeys.keys = [
    # TODO(eff): Decommission SSH key once we get into Bitwarden.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEI496sUFzVECzwdbjWFPwEyGp8tA6OuXKS3qedUXRnF" # tautologicc@illusions
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONucbKwW3mhpLJmWpl2Z9oEH13jldnCeopjwn4u4koV" # eff@snaz
  ];

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
}
