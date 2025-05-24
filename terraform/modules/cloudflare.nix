{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cloudflare;

  my = import ../../my pkgs;
in
{
  options.cloudflare.zones = lib.mkOption {
    description = "DNS zones";
    type =
      with lib.types;
      attrsOf (submodule {
        options.name = lib.mkOption {
          description = "Name of the DNS zone";
          type = str;
        };

        options.dnssec = lib.mkEnableOption "DNSSEC";

        # TODO(eff): Pass tags down to resources.
        options.tags = lib.mkOption {
          type = attrsOf (strMatching "[[:alnum:]_]+");
          default = { };
        };
      });
  };

  imports = [
    ./providers/cloudflare.nix
  ];

  config = {
    data.terraform_remote_state = my.tfRemoteStates [ "accounts/cloudflare" ];

    resource.cloudflare_zone = lib.mapAttrs (_: zone: {
      account.id = lib.tfRef "data.terraform_remote_state.accounts_cloudflare.outputs.id";
      inherit (zone) name;
      type = "full";
    }) cfg.zones;

    resource.cloudflare_zone_dns_settings = lib.mapAttrs (slug: _: {
      zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
      nameservers.type = "cloudflare.standard";
    }) cfg.zones;

    resource.cloudflare_zone_dnssec = lib.mapAttrs (slug: zone: {
      zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
      status = if zone.dnssec then "active" else "disabled";
    }) cfg.zones;

    output = lib.pipe cfg.zones [
      (lib.mapAttrsToList (
        slug: zone: {
          "zones_${slug}_id" = {
            description = "ID of DNS zone ${zone.name}";
            value = lib.tfRef "cloudflare_zone.${slug}.id";
          };

          "zones_${slug}_name" = {
            description = "Name of DNS zone ${zone.name}";
            value = lib.tfRef "cloudflare_zone.${slug}.name";
          };
        }
      ))
      (lib.foldl' lib.mergeAttrs { })
    ];
  };
}
