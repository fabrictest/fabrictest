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
  options.cloudflare.zones = mkOption {
    description = "DNS zones";
    type = attrsOf (submodule {
      options.name = mkOption {
        description = "Name of the DNS zone";
        type = str;
      };

      options.dnssec = mkEnableOption "DNSSEC";

      # TODO(eff): Pass tags down to resources.
      options.tags = mkOption {
        type = attrsOf (strMatching "[[:alnum:]_]+");
        default = { };
      };
    });
  };

  imports = [
    ./providers/cloudflare.nix
  ];

  config.data.terraform_remote_state = my.tfRemoteStates [ "accounts/cloudflare" ];

  config.resource.cloudflare_zone = mapAttrs (_: zone: {
    account.id = tfRef "data.terraform_remote_state.accounts_cloudflare.outputs.id";
    inherit (zone) name;
    type = "full";
  }) cfg.zones;

  config.resource.cloudflare_zone_dnssec = mapAttrs (slug: zone: {
    zone_id = tfRef "cloudflare_zone.${slug}.id";
    status = if zone.dnssec then "active" else "disabled";
  }) cfg.zones;

  config.output = foldl' mergeAttrs { } (
    mapAttrsToList (
      slug: zone: {
        "zones_${slug}_id" = {
          description = "ID of DNS zone ${zone.name}";
          value = tfRef "cloudflare_zone.${slug}.id";
        };

        "zones_${slug}_name" = {
          description = "Name of DNS zone ${zone.name}";
          value = tfRef "cloudflare_zone.${slug}.name";
        };
      }
    )
  );
}
