{
  imports = [
    ../../modules/backend/git.nix
    ../../modules/providers/migadu.nix
    ../../modules/migadu.nix
  ];

  backend.git.state = "services/migadu/live";

  migadu.domain.caixadecorre_io = {
    primary = {
      name = "caixadecorre.io";
      verify = "tloqjtbj";
    };
    aliases = [
    ];
  };
}
