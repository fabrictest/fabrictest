{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.tf.provider.random;
in
{
  options.tf.provider.random = mkOption {
    description = "Random provider settings";
    type = submodule {
      options.enable = mkEnableOption "provider";
    };
    default = { };
  };

  config = mkIf cfg.enable {
    terraform.required_providers.random.source = "hashicorp/random";
  };
}
