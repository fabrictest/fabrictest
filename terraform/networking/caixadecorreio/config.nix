{
  imports = [
    ../../modules/backend/git.nix
    ../../modules/migadu.nix
  ];

  backend.git.state = "networking/caixadecorreio";

  migadu = {
    domains."caixadecorre.io" = {
      verify = "tloqjtbj";
      aliases."ecorre.io" = {
        verify = "a8g9xgv4";
      };
      mailboxes = import ./mailboxes.nix;
    };

    # TODO(eff): Decommission domain.
    domains."decorre.io" = {
      verify = "y07nuop4";
    };
  };
}
