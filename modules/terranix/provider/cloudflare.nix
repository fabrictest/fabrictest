{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.provider.cloudflare;

  var_api_token = tfRef "var.cloudflare_api_token";
in
{
  options.provider.cloudflare = mkOption {
    description = "Settings for the Cloudflare provider";
    type = submodule {
      options.api_token = mkOption {
        description = "Token for accessing the Cloudflare API";
        type = str;
        default = var_api_token;
      };
    };
    default = { };
  };

  config.terraform.required_providers.cloudflare.source = "cloudflare/cloudflare";

  config.variable.cloudflare_api_token = mkIf (cfg.api_token == var_api_token) {
    description = "API token for accessing the Cloudflare API";
    type = "string";
    sensitive = true;
  };
}
