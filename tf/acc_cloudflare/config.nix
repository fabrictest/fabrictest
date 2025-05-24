{ lib, ... }:
let
  modules = import ../mod;
in
{
  imports = [
    modules.backend.git
    modules.providers.cloudflare
  ];

  backend.git.state = "accounts/cloudflare/live";

  resource.cloudflare_account.fabrictest = {
    name = "Fabric Test";
    type = "standard";
    settings = {
      abuse_contact_email = "abuse@fabricte.st";
      enforce_twofactor = true;
    };
  };

  output.id = {
    description = "ID of the account";
    value = lib.tfRef "cloudflare_account.fabrictest.id";
  };
}
