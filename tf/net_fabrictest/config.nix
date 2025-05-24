let
  modules = import ../mod;
in
{
  imports = [
    modules.backend.git
    modules.cloudflare
  ];

  backend.git.state = "network/live";

  cloudflare.zones.fabrictest_dev = {
    name = "fabrictest.dev";
    dnssec = true;
  };

  cloudflare.zones.fabrictest_live = {
    name = "fabrictest.live";
    dnssec = true;
  };

  cloudflare.zones.fabricte_st = {
    name = "fabricte.st";
  };

  cloudflare.zones.bricte_st = {
    name = "bricte.st";
  };

  cloudflare.zones.indosilver_club = {
    name = "indosilver.club";
    dnssec = true;
  };
}
