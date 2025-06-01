{ config, lib, ... }:
let
  l = lib // builtins;

  cfg = config.providers.migadu;

  var.username = l.tfRef "var.migadu_username";
  var.token = l.tfRef "var.migadu_token";
in
{
  options.providers.migadu = {
    username = l.mkOption {
      description = "Username for accessing the Migadu API";
      type = l.types.str;
      default = var.username;
    };
    token = l.mkOption {
      description = "Token for accessing the Migadu API";
      type = l.types.str;
      default = var.token;
    };
  };

  config = {
    terraform.required_providers.migadu.source = "metio/migadu";
    provider.migadu = cfg;
    variable.migadu_username = l.mkIf (cfg.username == var.username) {
      description = "Username for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };
    variable.migadu_token = l.mkIf (cfg.token == var.token) {
      description = "Token for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };
  };
}
