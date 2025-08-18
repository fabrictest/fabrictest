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
  dnssecWorksFor = zone: !lib.hasSuffix ".st" zone;
in
rec {
  imports = [ ../../../terranixModules ];

  tf.backend.state = "network/live";

  tf.provider.cloudflare.enable = true;

  tf.remote_state.accounts_cloudflare.config = ../../accounts/cloudflare/config.nix;

  resource.cloudflare_zone = lib.pipe zones [
    (map (zone: {
      name = lib.replaceString "." "_" zone;
      value.account.id = config.tf.remote_state.accounts_cloudflare.output.id;
      value.name = zone;
      value.type = "full";
    }))
    lib.listToAttrs
  ];

  resource.cloudflare_zone_dnssec = lib.pipe resource.cloudflare_zone [
    (lib.mapAttrs (_: { name, ... }: name))
    (lib.mapAttrs (
      slug: zone: {
        zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
        status = if dnssecWorksFor zone then "active" else "disabled";
      }
    ))
  ];

  output = lib.pipe resource.cloudflare_zone [
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
