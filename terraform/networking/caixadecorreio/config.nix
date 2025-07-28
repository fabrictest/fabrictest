{ pkgs, lib, ... }:
let
  my = import ../../my pkgs;

  domains =
    my.mapToAttrs
      (value: {
        name = lib.replaceString "." "_" value.name;
        inherit value;
      })
      [
        {
          name = "caixadecorre.io";
          hosted-email-verify = "tloqjtbj";
        }
        {
          name = "decorre.io";
          hosted-email-verify = "y07nuop4";
        }
      ];

  data.terraform_remote_state = my.tfRemoteStates [ "accounts/cloudflare" ];

  resource.cloudflare_zone = lib.mapAttrs (
    _:
    { name, ... }:
    {
      account.id = lib.tfRef "data.terraform_remote_state.accounts_cloudflare.outputs.id";
      inherit name;
      type = "full";
    }
  ) domains;

  resource.cloudflare_zone_dns_settings = lib.mapAttrs (slug: _: {
    zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
    nameservers.type = "cloudflare.standard";
    zone_mode = "standard";
    flatten_all_cnames = false;
    foundation_dns = false;
    multi_provider = false;
    secondary_overrides = false;
  }) resource.cloudflare_zone;

  resource.cloudflare_zone_dnssec = lib.mapAttrs (slug: _: {
    zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
    status = "active";
  }) resource.cloudflare_zone;

  dnsRecordsFor =
    slug:
    {
      name,
      hosted-email-verify,
      alias ? false,
    }:
    let
      zone_id = lib.tfRef "cloudflare_zone.${slug}.id";

      proto = "_tcp";

      records.mx =
        lib.pipe
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
            lib.cartesianProduct
            (my.mapToAttrs (
              { record, server }:
              lib.nameValuePair "${server}_${record.type}" {
                inherit zone_id;
                inherit (record) name;
                comment = "Mail eXchanger host #${server} (${record.type})";
                content = "aspmx${server}.migadu.com";
                priority = 10 * (lib.toInt server);
                ttl = 1;
                type = "MX";
              }
            ))
          ];

      records.dkim =
        lib.pipe
          {
            server = [
              "1"
              "2"
              "3"
            ];
          }
          [
            lib.cartesianProduct
            (my.mapToAttrs (
              { server }:
              lib.nameValuePair server {
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

      records.others =
        {
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
        // lib.optionalAttrs (!alias) {
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
    lib.pipe records [
      (lib.mapAttrsToList (
        type:
        let
          type_ = if type == "others" then "" else "${type}_";
        in
        lib.mapAttrs' (name: lib.nameValuePair "${slug}_${type_}${name}")
      ))
      (lib.foldl' lib.mergeAttrs { })
    ];

  resource.cloudflare_dns_record = lib.pipe domains [
    (lib.mapAttrsToList dnsRecordsFor)
    (lib.foldl' lib.mergeAttrs { })
  ];

in
{
  imports = [
    ../../modules/backend/git.nix
    ../../modules/providers/cloudflare.nix
  ];

  backend.git.state = "networking/caixadecorreio";

  inherit data resource;
}
