{ config, lib, ... }:
with lib;
with lib.types;
let
  var_username = tfRef "var.migadu_username";
  var_token = tfRef "var.migadu_token";
in
{
  options = {
    providers = {
      migadu = mkOption {
        description = "Migadu provider settings";
        type = submodule {
          options = {
            username = mkOption {
              description = "Username for accessing the Migadu API";
              type = str;
              default = var_username;
            };
            token = mkOption {
              description = "Token for accessing the Migadu API";
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
        migadu = {
          source = "metio/migadu";
        };
      };
    };
    provider = {
      inherit (config.providers) migadu;
    };
    variable = {
      migadu_username = mkIf (config.provider.migadu.username == var_username) {
        description = "Username for accessing the Migadu API";
        type = "string";
        sensitive = true;
      };
      migadu_token = mkIf (config.provider.migadu.token == var_token) {
        description = "Token for accessing the Migadu API";
        type = "string";
        sensitive = true;
      };
    };
  };
}
