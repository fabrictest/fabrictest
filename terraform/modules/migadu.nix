{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.types;
let
  cfg = config.migadu;

  my = import ../my pkgs;

  data.terraform_remote_state = my.tfRemoteStates [ "accounts/cloudflare" ];

  resource.cloudflare_zone = mapAttrs (
    _:
    { name, ... }:
    {
      inherit name;
      account.id = tfRef "data.terraform_remote_state.accounts_cloudflare.outputs.id";
      type = "full";
    }
  ) cfg.domains;

  resource.cloudflare_zone_dns_settings = mapAttrs (slug: _: {
    zone_id = tfRef "cloudflare_zone.${slug}.id";
    nameservers.type = "cloudflare.standard";
    zone_mode = "standard";
    flatten_all_cnames = false;
    foundation_dns = false;
    multi_provider = false;
    secondary_overrides = false;
  }) resource.cloudflare_zone;

  resource.cloudflare_zone_dnssec = mapAttrs (slug: _: {
    zone_id = tfRef "cloudflare_zone.${slug}.id";
    status = "active";
  }) resource.cloudflare_zone;

  dnsRecordsFor =
    slug:
    {
      name,
      hosted-email-verify,
      alias,
    }:
    let
      zone_id = tfRef "cloudflare_zone.${slug}.id";

      proto = "_tcp";

      records.mx =
        pipe
          {
            server = [
              "1"
              "2"
            ];
            record = [
              {
                type = "root";
                inherit name;
              }
              {
                type = "sub";
                name = "*.${name}";
              }
            ];
          }
          [
            cartesianProduct
            (my.mapToAttrs (
              { record, server }:
              nameValuePair "${server}_${record.type}" {
                inherit zone_id;
                inherit (record) name;
                comment = "Mail eXchanger host #${server} (${record.type})";
                content = "aspmx${server}.migadu.com";
                priority = 10 * (toInt server);
                ttl = 1;
                type = "MX";
              }
            ))
          ];

      records.dkim =
        pipe
          {
            server = [
              "1"
              "2"
              "3"
            ];
          }
          [
            cartesianProduct
            (my.mapToAttrs (
              { server }:
              nameValuePair server {
                inherit zone_id;
                type = "CNAME";
                name = "key${server}._domainkey.${name}";
                content = "key${server}.${name}._domainkey.migadu.com";
                ttl = 1;
                proxied = false;
                comment = "DKIM+ARC key #${server}";
              }
            ))
          ];

      records.others = {
        verification = {
          inherit zone_id name;
          type = "TXT";
          content = ''"hosted-email-verify=${hosted-email-verify}"'';
          ttl = 1;
          comment = "Migadu verification record";
        };

        spf = {
          inherit zone_id name;
          type = "TXT";
          content = ''"v=spf1 include:spf.migadu.com -all"'';
          ttl = 1;
          comment = "SPF record";
        };

        dmarc = {
          inherit zone_id;
          name = "_dmarc.${name}";
          type = "TXT";
          content = ''"v=DMARC1; p=quarantine;"'';
          ttl = 1;
          comment = "DMARC policy";
        };
      }
      // optionalAttrs (!alias) {
        autoconfig = {
          inherit zone_id;
          type = "CNAME";
          name = "autoconfig.${name}";
          content = "autoconfig.migadu.com";
          ttl = 1;
          proxied = false;
          comment = "Thunderbird autoconfig mechanism";
        };

        autodiscover = {
          inherit zone_id;
          type = "SRV";
          name = "_autodiscover.${proto}.${name}";
          data = {
            inherit name proto;
            target = "autodiscover.migadu.com";
            port = 443;
            priority = 0;
            weight = 1;
          };
          priority = 0;
          ttl = 1;
          comment = "Outlook autodiscovery mechanism";
        };

        smtp = {
          inherit zone_id;
          type = "SRV";
          name = "_submissions.${proto}.${name}";
          data = {
            inherit name proto;
            port = 465;
            priority = 0;
            target = "smtp.migadu.com";
            weight = 1;
          };
          priority = 0;
          ttl = 1;
          comment = "SMTP outgoing";
        };

        imap = {
          inherit zone_id;
          type = "SRV";
          name = "_imaps.${proto}.${name}";
          data = {
            inherit name proto;
            port = 993;
            priority = 0;
            target = "imap.migadu.com";
            weight = 1;
          };
          priority = 0;
          ttl = 1;
          comment = "IMAP incoming";
        };

        pop = {
          inherit zone_id;
          type = "SRV";
          name = "_pop3s.${proto}.${name}";
          data = {
            inherit name proto;
            target = "pop.migadu.com";
            port = 995;
            priority = 0;
            weight = 1;
          };
          priority = 0;
          ttl = 1;
          comment = "POP3 incoming";
        };
      };
    in
    pipe records [
      (mapAttrsToList (
        type:
        let
          type_ = if type == "others" then "" else "${type}_";
        in
        mapAttrs' (name: nameValuePair "${slug}_${type_}${name}")
      ))
      (foldl' mergeAttrs { })
    ];

  resource.cloudflare_dns_record = pipe cfg.domains [
    (mapAttrsToList dnsRecordsFor)
    (foldl' mergeAttrs { })
  ];

in
{
  options.migadu = mkOption {
    type = submodule {
      options.domains = mkOption {
        type = nullOr (
          attrsOf (submodule {
            options.name = mkOption {
              type = str;
            };
            options.hosted-email-verify = mkOption {
              type = str;
            };
            options.alias = mkOption {
              type = bool;
              default = false;
              example = true;
              description = "TODO TODO TODO TODO TODO";
            };
          })
        );
      };
    };
  };

  imports = [
    ./providers/cloudflare.nix
    ./providers/migadu.nix
  ];

  config = {
    inherit data resource;
  };
}
