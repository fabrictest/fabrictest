{ ... }:
{
  imports = [
    ../../modules/backend/git
    ../../modules/providers/cloudflare
    ../../modules/providers/migadu
    ../../modules/migadu
  ];

  backend.git.path = "migadu/live";

  migadu = {
    domains = {
      primary = {
        name = "fabricte.st";
        verification = "vsgdzd9q";
      };
      aliases = [
        {
          name = "bricte.st";
          verification = "xraav1ee";
        }
      ];
    };
  };
}
