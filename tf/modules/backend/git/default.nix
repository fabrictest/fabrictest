{ config, lib, ... }:
let
  l = lib // builtins;

  cfg = config.backend.git;
in
{
  options.backend.git = {
    path = l.mkOption {
      description = "The path to the state file in the Git repository.";
      type = l.types.str;
    };
  };

  config.terraform.backend.http =
    let
      address = "http://127.0.0.1:6061/?${params}";
      params = l.concatMapAttrsStringSep "&" (n: v: "${n}=${v}") {
        type = "git";
        repository = "git@github.com:fabrictest/tfstate";
        ref = "main";
        state = "${cfg.path}/terraform.tfstate";
      };
    in
    {
      inherit address;
      lock_address = address;
      unlock_address = address;
    };
}
