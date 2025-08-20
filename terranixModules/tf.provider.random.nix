{ config, lib, ... }:
let
  cfg = config.tf.provider.random;

  mkIfEnabled = lib.mkIf cfg.enable;
in
{
  options.tf.provider.random = lib.mkOption {
    description = "Random provider settings";
    type = lib.types.submodule {
      options.enable = lib.mkEnableOption "provider";
    };
    default = { };
  };

  config.terraform.required_providers = mkIfEnabled {
    random.source = "hashicorp/random";
  };
}
