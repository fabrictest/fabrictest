{ config, lib, ... }:
let
  cfg = config.tf.provider.cloudflare;

  mkIfEnabled = lib.mkIf cfg.enable;
in
{
  options.tf.provider.cloudflare = lib.mkOption {
    description = "Cloudflare provider settings";
    type = lib.types.submodule {
      options.enable = lib.mkEnableOption "provider";
    };
    default = { };
  };

  config.terraform.required_providers = mkIfEnabled {
    cloudflare.source = "cloudflare/cloudflare";
  };

  config.provider = mkIfEnabled {
    cloudflare.api_token = lib.tfRef "var.cloudflare_api_token";
  };

  config.variable = mkIfEnabled {
    cloudflare_api_token = {
      description = "API token for accessing the Cloudflare API";
      type = "string";
      sensitive = true;
    };
  };
}
