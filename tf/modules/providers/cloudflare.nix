{ config, lib, ... }:
let
  cfg = config.providers.cloudflare;

  var.api_token = lib.tfRef "var.cloudflare_api_token";

  modules.settings = {
    options.api_token = lib.mkOption {
      description = "Token for accessing the Cloudflare API";
      type = lib.types.str;
      default = var.api_token;
    };
  };
in
{
  options.providers.cloudflare = lib.mkOption {
    description = "Settings for the Cloudflare provider";
    type = lib.types.submodule modules.settings;
    default = { };
  };

  config = {
    terraform.required_providers.cloudflare.source = "cloudflare/cloudflare";

    provider.cloudflare = cfg;

    variable.cloudflare_api_token = lib.mkIf (cfg.api_token == var.api_token) {
      description = "Token for accessing the Cloudflare API";
      type = "string";
      sensitive = true;
    };
  };
}
