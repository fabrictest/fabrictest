{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cloudflare;

  my = import ../lib { inherit pkgs; };
in
{
  options.cloudflare.zone = lib.mkOption {
    description = "DNS zones";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.name = lib.mkOption {
          description = "Name of the DNS zone";
          type = lib.types.str;
        };

        options.dnssec = lib.mkEnableOption "DNSSEC";
      }
    );
  };

  config = {
    data.terraform_remote_state.accounts_cloudflare = my.tfRemoteState ../accounts/cloudflare/config.nix;

    resource.cloudflare_zone = lib.mapAttrs (_: zone: {
      account.id = lib.tfRef "data.terraform_remote_state.accounts_cloudflare.outputs.account_id";
      inherit (zone) name;
      type = "full";
    }) cfg.zone;

    resource.cloudflare_zone_dns_settings = lib.mapAttrs (slug: _: {
      zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
      nameservers.type = "cloudflare.standard";
    }) cfg.zone;

    resource.cloudflare_zone_dnssec = lib.mapAttrs (slug: zone: {
      zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
      status = if zone.dnssec then "active" else "disabled";
    }) cfg.zone;

    output = lib.pipe cfg.zone [
      (lib.mapAttrsToList (
        slug: _zone: {
          "zone_${slug}_id" = {
            description = "ID of the DNS zone";
            value = lib.tfRef "cloudflare_zone.${slug}.id";
          };

          "zone_${slug}_name" = {
            description = "Name of the DNS zone";
            value = lib.tfRef "cloudflare_zone.${slug}.name";
          };
        }
      ))
      (lib.foldl' lib.mergeAttrs { })
    ];
  };
}
