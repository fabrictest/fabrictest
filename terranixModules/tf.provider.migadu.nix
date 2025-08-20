{ config, lib, ... }:
let
  cfg = config.tf.provider.migadu;

  mkIfEnabled = lib.mkIf cfg.enable;
in
{
  options.tf.provider.migadu = lib.mkOption {
    description = "Migadu provider settings";
    type = lib.types.submodule {
      options.enable = lib.mkEnableOption "provider";
    };
    default = { };
  };

  config.terraform.required_providers = mkIfEnabled {
    migadu.source = "metio/migadu";
  };

  config.provider = mkIfEnabled {
    migadu.username = lib.tfRef "var.migadu_username";
    migadu.token = lib.tfRef "var.migadu_token";
  };

  config.variable = mkIfEnabled {
    migadu_username = {
      description = "Username for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };
    migadu_token = {
      description = "Token for accessing the Migadu API";
      type = "string";
      sensitive = true;
    };
  };
}
