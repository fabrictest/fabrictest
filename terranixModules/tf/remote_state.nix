{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.tf.remote_state;
in
{
  options.tf.remote_state = lib.mkOption {
    description = ''
      Remote state settings.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule {
        imports = [ (pkgs.terranix + /core/terraform-options.nix) ];
        options.output = lib.mkOption {
          description = "TODO";
          type = lib.types.attrsOf lib.types.nonEmptyStr;
          readOnly = true;
        };
      }
    );
    default = { };
  };

  config = lib.pipe cfg [
    (lib.mapAttrsToList (
      resource: terranix_config:
      let
        terranixConfig = import (pkgs.terranix + /core) { inherit pkgs terranix_config; };
      in
      {
        data.terraform_remote_state.${resource} = rec {
          backend = "http";
          config = terranixConfig.config.terraform.backend.${backend};
        };
        tf.remote_state.${resource}.output = lib.mapAttrs (
          output: _: lib.tfRef "data.terraform_remote_state.${resource}.outputs.${output}"
        ) terranixConfig.config.output;
      }
    ))
    lib.mkMerge
  ];
}
