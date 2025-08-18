{ lib, ... }:
{
  imports = [ ../../../terranixModules ];

  tf.backend.state = "accounts/cloudflare/live";

  tf.provider.cloudflare.enable = true;

  resource.cloudflare_account.fabrictest = {
    name = "Fabric Test";
    type = "standard";
    settings = {
      abuse_contact_email = "abuse@fabricte.st";
      enforce_twofactor = true;
    };
  };

  output.id = {
    description = "Account identifier";
    value = lib.tfRef "cloudflare_account.fabrictest.id";
  };
}
