{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.providers.migadu;

  var_username = tfRef "var.migadu_username";
  var_token = tfRef "var.migadu_token";
in
{
  options.providers.migadu = mkOption {
    description = "Migadu provider settings";
    type = submodule {
      options.username = mkOption {
        description = "Username for accessing the Migadu API";
        type = str;
        default = var_username;
      };

      options.token = mkOption {
        description = "Token for accessing the Migadu API";
        type = str;
        default = var_token;
      };
    };
    default = { };
  };

  config = {
    terraform.required_providers.migadu.source = "metio/migadu";

    provider.migadu = cfg;

    variable.migadu_username = mkIf (cfg.username == var_username) {
      description = "Username for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };

    variable.migadu_token = mkIf (cfg.token == var_token) {
      description = "Token for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };
  };
}
