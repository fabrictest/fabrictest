{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.tf.provider.migadu;
in
{
  options.tf.provider.migadu = mkOption {
    description = "Migadu provider settings";
    type = submodule {
      options.enable = mkEnableOption "provider";
    };
    default = { };
  };

  config = mkIf cfg.enable {
    terraform.required_providers.migadu.source = "metio/migadu";

    provider.migadu = {
      username = tfRef "var.migadu_username";
      token = tfRef "var.migadu_token";
    };

    variable.migadu_username = {
      description = "Username for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };

    variable.migadu_token = {
      description = "Token for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };
  };
}
