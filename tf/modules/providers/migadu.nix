{ config, lib, ... }:
let
  cfg = config.providers.migadu;

  var.username = lib.tfRef "var.migadu_username";
  var.token = lib.tfRef "var.migadu_token";

  modules.settings = {
    options.username = lib.mkOption {
      description = "Username for accessing the Migadu API";
      type = lib.types.str;
      default = var.username;
    };

    options.token = lib.mkOption {
      description = "Token for accessing the Migadu API";
      type = lib.types.str;
      default = var.token;
    };
  };

in
{
  options.providers.migadu = lib.mkOption {
    description = "Migadu provider settings";
    type = lib.types.submodule modules.settings;
    default = { };
  };

  config = {
    terraform.required_providers.migadu.source = "metio/migadu";

    provider.migadu = cfg;

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
