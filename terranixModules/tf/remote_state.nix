{
  config,
  lib,
  pkgs,
  ...
}:
let
  tfConfigAst = terranix_config: import (pkgs.terranix + /core) { inherit pkgs terranix_config; };

  cfg = config.tf.remote_state;
in
{
  options.tf.remote_state = lib.mkOption {
    description = ''
      Remote state settings.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule (
        {
          config,
          name,
          ...
        }:
        {
          options.config = lib.mkOption {
            description = "TODO";
            type = lib.types.path;
            apply = config: (tfConfigAst config).config;
          };
          options.output = lib.mkOption {
            description = "TODO";
            type = lib.types.attrsOf lib.types.nonEmptyStr;
            readOnly = true;
            default = lib.mapAttrs (
              output: _: lib.tfRef "data.terraform_remote_state.${name}.outputs.${output}"
            ) (config.config.output or { });
          };
        }
      )
    );
    default = { };
  };

  config.data.terraform_remote_state = lib.mkIf (cfg != { }) (
    lib.mapAttrs (
      _:
      { config, ... }:
      {
        backend = "http";
        config = config.terraform.backend.http;
      }
    ) cfg
  );
}
