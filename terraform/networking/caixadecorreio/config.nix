{ ... }:
{
  imports = [
    ../../modules/backend/git.nix
    ../../modules/migadu.nix
  ];

  config = {
    backend.git.state = "networking/caixadecorreio";

    migadu = {
      domains = {
        caixadecorre_io = {
          name = "caixadecorre.io";
          hosted-email-verify = "tloqjtbj";
        };
        decorre_io = {
          name = "decorre.io";
          hosted-email-verify = "y07nuop4";
        };
      };
    };
  };
}
