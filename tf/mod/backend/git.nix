{ config, lib, ... }:
let
  cfg = config.backend.git;
in
{
  options.backend.git = lib.mkOption {
    description = "Terraform back-end settings";
    type =
      with lib.types;
      submodule {
        options.repo = lib.mkOption {
          description = "URL of the Git repository";
          type = str;
          default = "git@github.com:fabrictest/terraform.tfstate";
        };

        options.branch = lib.mkOption {
          description = "Branch to store the authoritative state";
          type = str;
          default = "main";
        };

        options.state = lib.mkOption {
          description = "Path to the state directory in the Git repository";
          type = str;
        };
      };

    default = { };
  };

  config = {
    terraform.backend.http = rec {
      address = "http://127.0.0.1:6061/?${
        lib.concatMapAttrsStringSep "&" (n: v: "${n}=${v}") {
          type = "git";
          repository = cfg.repo;
          ref = cfg.branch;
          state = "${cfg.state}/terraform.tfstate";
        }
      }";
      lock_address = address;
      unlock_address = address;
    };
  };
}
