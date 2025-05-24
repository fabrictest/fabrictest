{
  backend = {
    git = ./backend/git.nix;
  };

  providers = {
    cloudflare = ./providers/cloudflare.nix;
    migadu = ./providers/migadu.nix;
    random = ./providers/random.nix;
  };

  cloudflare = ./cloudflare.nix;
}
