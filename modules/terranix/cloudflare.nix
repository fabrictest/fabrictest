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

            # TODO(eff): Pass tags down to resources.
            tags = mkOption {
              type = attrsOf (strMatching "[[:alnum:]_]+");
              default = { };
            };
          };
        });
      };
    };
  };

  imports = [
    ./providers/cloudflare.nix
  ];

  config = {
    data = {
      terraform_remote_state = my.terraformRemoteStates [ "accounts/cloudflare" ];
    };
    resource = {
      cloudflare_zone = pipe cfg [
        (getAttr "zones")
        (mapAttrs (_: getAttr "name"))
        (mapAttrs (
          _: name: {
            account = {
              id = tfRef "data.terraform_remote_state.accounts_cloudflare.outputs.id";
            };
            inherit name;
            type = "full";
          }
        ))
      ];
      cloudflare_zone_dnssec = pipe cfg [
        (getAttr "zones")
        (mapAttrs (_: getAttr "dnssec"))
        (mapAttrs (
          slug: dnssec: {
            zone_id = tfRef "cloudflare_zone.${slug}.id";
            status = if dnssec then "active" else "disabled";
          }
        ))
      ];
    };

    output = pipe cfg [
      (getAttr "zones")
      (mapAttrs (_: getAttr "name"))
      (mapAttrsToList (
        slug: name: {
          "zones_${slug}_id" = {
            description = "ID of DNS zone ${name}";
            value = tfRef "cloudflare_zone.${slug}.id";
          };

          "zones_${slug}_name" = {
            description = "Name of DNS zone ${name}";
            value = tfRef "cloudflare_zone.${slug}.name";
          };
        }
      ))
      mergeAttrsList
    ];
  };

}
