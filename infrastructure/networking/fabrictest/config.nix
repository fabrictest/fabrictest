{ config, lib, ... }:
let
  zones = [
    "bricte.st"
    "fabricte.st"
    "fabrictest.dev"
    "fabrictest.live"
    # "fa.bricte.st"
    "indosilver.club"
  ];

  outputs = [
    {
      output = "id";
      name = "ID";
    }
    {
      output = "name";
      name = "Name";
    }
  ];

  # NOTE(eff): The .st ccTLD doesn't support DNSSEC (yet?).
  dnssecWorksFor = !lib.hasSuffix ".st";
in
{
  imports = [ ../../../terranixModules ];

  tf.backend.state = "network/live";

  tf.remote_state.accounts_cloudflare = ../../accounts/cloudflare/config.nix;

  resource.cloudflare_zone = lib.pipe zones [
    (map (zone: {
      name = lib.replaceString "." "_" zone;
      value = {
        account = { inherit (config.tf.remote_state.accounts_cloudflare.output) id; };
        name = zone;
        type = "full";
      };
    }))
    lib.listToAttrs
  ];

  resource.cloudflare_zone_dnssec = lib.pipe config.resource.cloudflare_zone [
    (lib.mapAttrs (_: { name, ... }: name))
    (lib.mapAttrs (
      slug: zone: {
        zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
        status = if dnssecWorksFor zone then "active" else "disabled";
      }
    ))
  ];

  output = lib.pipe config.resource.cloudflare_zone [
    (lib.mapAttrs (_: { name, ... }: name))
    (lib.mapAttrsToList (
      slug: zone:
      lib.map (
        { output, name }:
        {
          name = "zone_${slug}_${output}";
          value.description = "${name} of the DNS zone ${zone}";
          value.value = lib.tfRef "cloudflare_zone.${slug}.${output}";
        }
      ) outputs
    ))
    lib.flatten
    lib.listToAttrs
  ];
}
