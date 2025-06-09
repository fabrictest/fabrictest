{
  imports = [
    ../modules/backend/git.nix
    ../modules/providers/cloudflare.nix
    ../modules/cloudflare.nix
  ];

  backend.git.state = "network/live";

  cloudflare.zone.fabrictest_dev = {
    name = "fabrictest.dev";
    dnssec = true;
  };

  cloudflare.zone.fabrictest_live = {
    name = "fabrictest.live";
    dnssec = true;
  };

  cloudflare.zone.fabricte_st = {
    name = "fabricte.st";
  };

  cloudflare.zone.bricte_st = {
    name = "bricte.st";
  };

  cloudflare.zone.caixadecorre_io = {
    name = "caixadecorre.io";
    dnssec = true;
  };
}
