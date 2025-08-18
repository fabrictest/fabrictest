{ config, lib, ... }:
let
  cfg = config.tf.provider;
in
lib.mkMerge [
  {
    options.tf.provider = lib.mkOption {
      description = "Provider settings";
      type = lib.types.submodule {
        options.cloudflare = lib.mkOption {
          description = "Cloudflare provider settings";
          type = lib.types.submodule {
            options.enable = lib.types.mkEnableOption "provider";
          };
          default = { };
        };
        options.migadu = lib.mkOption {
          description = "Cloudflare provider settings";
          type = lib.types.submodule {
            options.enable = lib.types.mkEnableOption "provider";
          };
          default = { };
        };
        options.random = lib.mkOption {
          description = "Random provider settings";
          type = lib.types.submodule {
            options.enable = lib.types.mkEnableOption "provider";
          };
          default = { };
        };
      };
      default = { };
    };
  }

  (lib.mkIf cfg.cloudflare.enable {
    config.terraform.required_providers.cloudflare.source = "cloudflare/cloudflare";

    config.provider.cloudflare.api_token = lib.tfRef "var.cloudflare_api_token";

    config.variable.cloudflare_api_token = {
      description = "API token for accessing the Cloudflare API";
      type = "string";
      sensitive = true;
    };
  })

  (

    lib.mkIf cfg.migadu.enable {
      config.terraform.required_providers.migadu.source = "metio/migadu";

      config.provider.migadu = {
        username = lib.tfRef "var.migadu_username";
        token = lib.tfRef "var.migadu_token";
      };

      config.variable.migadu_username = {
        description = "Username for accessing the Migadu API";
        type = "string";
        sensitive = true;
      };

      config.variable.migadu_token = {
        description = "Token for accessing the Migadu API";
        type = "string";
        sensitive = true;
      };
    }
  )

  (lib.mkIf cfg.random.enable {
    config.terraform.required_providers.random.source = "hashicorp/random";
  })
]
