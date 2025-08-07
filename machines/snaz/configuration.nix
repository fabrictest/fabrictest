{
  imports = [ ./gnome.nix ];

  users.users.root.openssh.authorizedKeys.keys = [
    # TODO(eff): Rotate SSH key.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEI496sUFzVECzwdbjWFPwEyGp8tA6OuXKS3qedUXRnF"
  ];
}
