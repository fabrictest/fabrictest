{ lib, ... }:
let
  l = lib // builtins;
in
{
  imports = [
    ../../modules/backend/git
    ../../modules/providers/cloudflare
  ];

  backend.git.path = "accounts/cloudflare/live";

  resource.cloudflare_account.fabrictest = {
    name = "Fabric Test";
    type = "standard";
    settings = {
      abuse_contact_email = "abuse@fabricte.st";
      enforce_twofactor = true;
    };
  };

  output.account_id.value = l.tfRef "cloudflare_account.fabrictest.id";
}
