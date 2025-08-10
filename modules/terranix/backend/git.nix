{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.backend.git;
in
{
  options = {
    backend = {
      git = mkOption {
        description = "Terraform back-end settings";

        type = submodule {
          options = {
            type = mkOption {
              type = "str";
              default = "git";
              internal = true;
              visible = false;
            };

            repository = mkOption {
              description = "URL of the Git repository";
              type = str;
              default = "git@github.com:fabrictest/terraform.tfstate";
            };

            ref = mkOption {
              description = "Branch to store the authoritative state";
              type = str;
              default = "main";
            };

            state = mkOption {
              description = "Path to the state directory in the Git repository";
              type = str;
              apply = p: p ++ "/terraform.tfstate";
            };
          };
        };

        default = { };
      };
    };
  };

  config = {
    terraform = {
      backend = {
        http = rec {
          address = "http://127.0.0.1:6061/?${concatMapAttrsStringSep "&" (n: v: "${n}=${v}") cfg}";
          lock_address = address;
          unlock_address = address;
        };
      };
    };
  };

}
