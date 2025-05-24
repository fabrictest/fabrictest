{ config, lib, ... }:
let
  cfg = config.providers.migadu;

  var.username = lib.tfRef "var.migadu_username";
  var.token = lib.tfRef "var.migadu_token";
in
{
  options.providers.migadu = lib.mkOption {
    description = "Migadu provider settings";
    type =
      with lib.types;
      submodule {
        options.username = lib.mkOption {
          description = "Username for accessing the Migadu API";
          type = str;
          default = var.username;
        };

        options.token = lib.mkOption {
          description = "Token for accessing the Migadu API";
          type = str;
          default = var.token;
        };
      };
    default = { };
  };

  config = {
    terraform.required_providers.migadu.source = "metio/migadu";

    provider.migadu = { inherit (cfg) username token; };

    variable.migadu_username = lib.mkIf (cfg.username == var.username) {
      description = "Username for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };

    variable.migadu_token = lib.mkIf (cfg.token == var.token) {
      description = "Token for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };
  };
}
