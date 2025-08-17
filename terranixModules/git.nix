{ config, lib, ... }:
with lib;
with lib.types;
let
  cfg = config.terraform.backend.git;
in
{
  options.terraform.backend.git = mkOption {
    description = "Git back-end settings";
    type = submodule {
      options.type = {
        type = enum [ "git" ];
        default = "git";
        internal = true;
        visible = false;
      };
      options.repository = mkOption {
        description = "URL of the Git repository";
        type = str;
        default = "git@github.com:fabrictest/terraform.tfstate";
      };
      options.ref = mkOption {
        description = "Branch to store the authoritative state";
        type = str;
        default = "main";
      };
      options.state = mkOption {
        description = "Path to the state directory in the Git repository";
        type = str;
        apply = s: s + "/terraform.tfstate";
      };
    };
    default = { };
  };

  config.terraform.backend.http =
    let
      address = "http://127.0.0.1:6061/?${queryStr}";
      queryStr = concatMapAttrsStringSep "&" (n: v: "${n}=${v}") {
        inherit (cfg)
          type
          repository
          ref
          state
          ;
      };
    in
    {
      inherit address;
      lock_address = address;
      unlock_address = address;
    };
}
