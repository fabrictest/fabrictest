{
  config,
  lib,
  ...
}:
let
  cfg = config.tf.backend;
in
{
  options.tf.backend = lib.mkOption {
    description = "Back-end settings.";
    type = lib.types.nullOr (
      lib.types.submodule {
        options.repo = lib.mkOption {
          description = ''
            URL of the Git repository.
          '';
          type = lib.types.nonEmptyStr;
          default = "git@github.com:fabrictest/terraform.tfstate";
        };
        options.branch = lib.mkOption {
          description = ''
            Branch where the authoritative state resides.
          '';
          type = lib.types.nonEmptyStr;
          default = "main";
        };
        options.state = lib.mkOption {
          description = ''
            Path to the state directory in the repository.
          '';
          type = lib.types.pathWith {
            absolute = false;
          };
          apply = state: state + "/terraform.tfstate";
        };
      }
    );
    default = null;
  };

  config = lib.mkIf (cfg != null) {
    terraform.backend.http = rec {
      address = "http://127.0.0.1:6061/?${
        lib.concatMapAttrsStringSep "&" (n: v: "${n}=${v}") {
          type = "git";
          repository = cfg.repo;
          ref = cfg.branch;
          inherit (cfg) state;
        }
      }";
      lock_address = address;
      unlock_address = address;
    };
  };
}
