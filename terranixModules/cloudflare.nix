{
  config,
  lib,
  # pkgs,
  ...
}:
let
  cfg = config.cloudflare;

  # my = import ../../my pkgs;
in
{
  options.cloudflare = lib.mkOption {
    description = "TODO";
    type = lib.submodule {
      options.zone = lib.mkOption {
        description = "DNS zones";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.name = lib.mkOption {
              description = "Name of the zone";
              type = lib.types.nonEmptyStr;
            };
            options.dnssec = lib.mkEnableOption "DNSSEC";
          }
        );
        default = { };
      };
    };
    default = { };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.zone != { }) {
      # data.terraform_remote_state = my.terraformRemoteStates [ "accounts/cloudflare" ];
      tf.remote_state.accounts_cloudflare = ../infrastructure/accounts/cloudflare/config.nix;

      output =
        let
          zoneOutputs = [
            {
              output = "id";
              description = "ID of the DNS zone";
            }
            {
              output = "name";
              description = "Name of the DNS zone";
            }
          ];
          genZoneOutputs =
            name:
            let
              genZoneOutput =
                { description, output }:
                {
                  name = "zones_${name}_${output}";
                  value = {
                    inherit description;
                    value = lib.tfRef "cloudflare_zone.${name}.${output}";
                  };
                };
            in
            lib.map genZoneOutput zoneOutputs;
        in
        lib.pipe cfg.zone [
          lib.attrNames
          (lib.map genZoneOutputs)
          lib.flatten
          lib.listToAttrs
        ];
    })
  ];
}
