{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.cloudflare;

  my = import ../../my pkgs;
in
{
  options = {
    cloudflare = {
      zones = mkOption {
        description = "DNS zones";
        type = attrsOf (submodule {
          options = {
            name = mkOption {
              description = "Name of the DNS zone";
              type = str;
            };
            dnssec = mkEnableOption "DNSSEC";
          };
        });
      };
    };
  };

  imports = [
    ./provider/cloudflare.nix
  ];

  config = {
    data = {
      terraform_remote_state = my.terraformRemoteStates [ "accounts/cloudflare" ];
    };

    resource = {
      cloudflare_zone = mapAttrs (
        _:
        { name, ... }:
        {
          inherit name;
          account = {
            id = tfRef "data.terraform_remote_state.accounts_cloudflare.outputs.id";
          };
          type = "full";
        }
      ) cfg.zones;

      cloudflare_zone_dnssec = mapAttrs (
        slug:
        { dnssec, ... }:
        {
          zone_id = tfRef "cloudflare_zone.${slug}.id";
          status = if dnssec then "active" else "disabled";
        }
      ) cfg.zones;
    };

    output =
      let
        zoneOutputs = [
          {
            value = "id";
            description = "ID of the DNS zone";
          }
          {
            value = "name";
            description = "Name of the DNS zone";
          }
        ];
        genZoneOutputs =
          name:
          let
            genZoneOutput =
              { description, value }:
              {
                name = "zones_${name}_${value}";
                value = {
                  inherit description;
                  value = tfRef "cloudflare_zone.${name}.${value}";
                };
              };
          in
          map genZoneOutput zoneOutputs;
      in
      pipe cfg.zones [
        attrNames
        (map genZoneOutputs)
        flatten
        listToAttrs
      ];
  };
}
