{ lib, ... }:
with lib;
with lib.types;
{
  options.provider.random = mkOption {
    description = "Random provider settings";
    type = submodule { };
    default = { };
  };

  config.terraform.required_providers.random.source = "hashicorp/random";
}
