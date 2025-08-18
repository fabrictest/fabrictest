{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.tf.provider.cloudflare;
in
{
  options.tf.provider.cloudflare = mkOption {
    description = "Cloudflare provider settings";
    type = submodule {
      options.enable = mkEnableOption "provider";
    };
    default = { };
  };

  config = mkIf cfg.enable {
    terraform.required_providers.cloudflare.source = "cloudflare/cloudflare";

    provider.cloudflare.api_token = tfRef "var.cloudflare_api_token";

    variable.cloudflare_api_token = {
      description = "API token for accessing the Cloudflare API";
      type = "string";
      sensitive = true;
    };
  };

}
