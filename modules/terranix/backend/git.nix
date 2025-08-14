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
            repository = mkOption {
              description = "URL of the Git repository";
              type = str;
              default = "git@github.com:fabrictest/terraform.tfstate";
            };
            branch = mkOption {
              description = "Branch to store the authoritative state";
              type = str;
              default = "main";
            };
            state = mkOption {
              description = "Path to the state directory in the Git repository";
              type = str;
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
        http =
          let
            address = "http://127.0.0.1:6061/?${queryStr}";
            queryStr = concatMapAttrsStringSep "&" (n: v: "${n}=${v}") {
              inherit (cfg) repository;
              type = "git";
              ref = cfg.branch;
              state = "${cfg.state}/terraform.tfstate";
            };
          in
          {
            inherit address;
            lock_address = address;
            unlock_address = address;
          };
      };
    };
  };

}
