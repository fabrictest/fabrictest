{ config, lib, ... }:
let
  cfg = config.backend.git;

  modules.settings = {
    options.repository = lib.mkOption {
      description = "URL of the Git repository";
      type = lib.types.str;
      default = "git@github.com:fabrictest/terraform.tfstate";
    };

    options.ref = lib.mkOption {
      description = "Branch to store the authoritative state";
      type = lib.types.str;
      default = "main";
    };

    options.state = lib.mkOption {
      description = "Path to the state directory in the Git repository";
      type = lib.types.str;
      apply = state: state + "/terraform.tfstate";
    };

    options.type = lib.mkOption {
      type = lib.types.str;
      default = "git";
      internal = true;
      readOnly = true;
    };
  };
in
{
  options.backend.git = lib.mkOption {
    description = "Terraform back-end settings";
    type = lib.types.submodule modules.settings;
    default = { };
  };

  config = {
    terraform.backend.http = rec {
      address = "http://127.0.0.1:6061/?${lib.concatMapAttrsStringSep "&" (n: v: "${n}=${v}") cfg}";
      lock_address = address;
      unlock_address = address;
    };
  };
}
