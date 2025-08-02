{
  imports = [
    ../../modules/backend/git.nix
    ../../modules/migadu.nix
  ];

  config = {
    backend.git.state = "networking/caixadecorreio";

    migadu = {
      domains."caixadecorre.io" = {
        verify = "tloqjtbj";

        mailboxes.emerson.admin = true;

        mailboxes.emerson.name = "F. Emerson";
        mailboxes.flora.name = "Flora Branchi";
      };

      domains."decorre.io" = {
        verify = "y07nuop4";
      };
    };
  };
}
