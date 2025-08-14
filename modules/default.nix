{
  terranix = {
    backend = {
      git = ./terranix/backend/git.nix;
    };
    providers = {
      cloudflare = ./terranix/providers/cloudflare.nix;
      migadu = ./terranix/providers/migadu.nix;
      random = ./terranix/providers/random.nix;
    };
    cloudflare = ./terranix/cloudflare.nix;
    migadu = ./terranix/migadu.nix;
  };
}
