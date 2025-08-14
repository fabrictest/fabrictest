{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.providers.cloudflare;

  var_token = tfRef "var.cloudflare_token";
in
{
  options = {
    providers = {
      cloudflare = mkOption {
        description = "Settings for the Cloudflare provider";
        type = submodule {
          options = {
            token = mkOption {
              description = "Token for accessing the Cloudflare API";
              type = str;
              default = var_token;
            };
          };
        };
        default = { };
      };
    };
  };
  config = {
    terraform = {
      required_providers = {
        cloudflare = {
          source = "cloudflare/cloudflare";
        };
      };
    };
    provider = {
      cloudflare = {
        api_token = cfg.token;
      };
    };
    variable = {
      cloudflare_token = mkIf (cfg.token == var_token) {
        description = "Token for accessing the Cloudflare API";
        type = "string";
        sensitive = true;
      };
    };
  };
}
