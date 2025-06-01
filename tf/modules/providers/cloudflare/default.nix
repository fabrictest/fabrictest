{ config, lib, ... }:
let
  l = lib // builtins;

  cfg = config.providers.cloudflare;

  var.api_token = l.tfRef "var.cloudflare_api_token";
in
{
  options.providers.cloudflare = {
    api_token = l.mkOption {
      description = "Token for accessing the Cloudflare API";
      type = l.types.str;
      default = var.api_token;
    };
  };

  config = {
    terraform.required_providers.cloudflare.source = "cloudflare/cloudflare";
    provider.cloudflare = cfg;
    variable.cloudflare_api_token = l.mkIf (cfg.api_token == var.api_token) {
      description = "Token for accessing the Cloudflare API";
      type = "string";
      sensitive = true;
    };
  };
}
