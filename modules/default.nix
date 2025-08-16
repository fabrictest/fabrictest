{
  terranix = {
    backend = {
      git = ./terranix/backend/git.nix;
    };
    provider = {
      cloudflare = ./terranix/provider/cloudflare.nix;
      migadu = ./terranix/provider/migadu.nix;
      random = ./terranix/provider/random.nix;
    };
    cloudflare = ./terranix/cloudflare.nix;
    migadu = ./terranix/migadu.nix;
  };
}
