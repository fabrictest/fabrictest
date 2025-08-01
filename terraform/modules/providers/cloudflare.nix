{ config, lib, ... }:
let
  cfg = config.providers.cloudflare;

  var_token = lib.tfRef "var.cloudflare_token";
in
{
  options.providers.cloudflare = lib.mkOption {
    description = "Settings for the Cloudflare provider";
    type =
      with lib.types;
      submodule {
        options.token = lib.mkOption {
          description = "Token for accessing the Cloudflare API";
          type = str;
          default = var_token;
        };
      };
    default = { };
  };

  config = {
    terraform.required_providers.cloudflare.source = "cloudflare/cloudflare";

    provider.cloudflare.api_token = cfg.token;

    variable.cloudflare_token = lib.mkIf (cfg.token == var_token) {
      description = "Token for accessing the Cloudflare API";
      type = "string";
      sensitive = true;
    };
  };
}
