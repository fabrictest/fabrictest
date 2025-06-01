{
  config,
  lib,
  pkgs,
  ...
}:
let
  l = lib // builtins;

  cfg = config.migadu;

  my = import ../../my { inherit pkgs; };

  domainSubmodule =
    {
      primary ? false,
    }:
    l.types.submodule {
      options = {
        name = l.mkOption {
          description = "Name of the DNS zone";
          type = l.types.str;
        };
        verification = l.mkOption {
          description = "Token for the Migadu service, used for DNS verification";
          type = l.types.str;
        };
        primary = l.mkOption {
          description = "Whether this is the primary domain for the Migadu service";
          type = l.types.bool;
          default = primary;
          internal = true;
          readOnly = true;
        };
      };
    };

  domainsSubmodule = l.types.submodule {
    options = {
      primary = l.mkOption {
        description = "Primary domain for the Migadu service";
        type = domainSubmodule { primary = true; };
      };
      aliases = l.mkOption {
        description = "List of domain aliases for the Migadu service";
        type = l.types.listOf (domainSubmodule { });
        default = [ ];
      };
    };
  };

  dnsRecordsFor =
    {
      name,
      verification,
      primary,
    }:
    let
      slug = l.replaceStrings [ "." ] [ "_" ] name;

      zone_id = l.tfRef "data.terraform_remote_state.networking.outputs.${slug}_zone_id";
      tags = [
        # "service:migadu"
      ];

      proto = "_tcp";

      records.mx =
        l.pipe
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
            l.cartesianProduct
            (l.map (
              { record, server }:
              l.nameValuePair "${server}_${record.type}" {
                inherit tags zone_id;
                comment = "Mail eXchanger host #${server} (${record.type})";
                content = "aspmx${server}.migadu.com";
                inherit (record) name;
                priority = 10 * (l.toInt server);
                ttl = 1;
                type = "MX";
              }
            ))
            l.listToAttrs
          ];

      records.dkim =
        l.pipe
          {
            server = [
              "1"
              "2"
              "3"
            ];
          }
          [
            l.cartesianProduct
            (l.map (
              { server }:
              l.nameValuePair server {
                inherit tags zone_id;
                comment = "DKIM+ARC key #${server}";
                content = "key${server}.${name}._domainkey.migadu.com";
                name = "key${server}._domainkey.${name}";
                proxied = false;
                ttl = 1;
                type = "CNAME";
              }
            ))
            l.listToAttrs
          ];

      records.others =
        {
          verification = {
            inherit tags zone_id;
            comment = "Migadu verification record";
            content = ''"hosted-email-verify=${verification}"'';
            inherit name;
            ttl = 1;
            type = "TXT";
          };

          spf = {
            inherit tags zone_id;
            comment = "SPF record";
            content = ''"v=spf1 include:spf.migadu.com -all"'';
            inherit name;
            ttl = 1;
            type = "TXT";
          };

          dmarc = {
            inherit tags zone_id;
            comment = "DMARC policy";
            content = ''"v=DMARC1; p=quarantine;"'';
            name = "_dmarc.${name}";
            ttl = 1;
            type = "TXT";
          };
        }
        // l.optionalAttrs primary {
          autoconfig = {
            inherit tags zone_id;
            comment = "Thunderbird autoconfig mechanism";
            content = "autoconfig.migadu.com";
            name = "autoconfig.${name}";
            proxied = false;
            ttl = 1;
            type = "CNAME";
          };

          autodiscover = {
            inherit tags zone_id;
            comment = "Outlook autodiscovery mechanism";
            data = {
              inherit name proto;
              port = 443;
              priority = 0;
              target = "autodiscover.migadu.com";
              weight = 1;
            };
            name = "_autodiscover.${proto}.${name}";
            priority = 0;
            ttl = 1;
            type = "SRV";
          };

          smtp = {
            inherit tags zone_id;
            comment = "SMTP outgoing";
            data = {
              inherit name proto;
              port = 465;
              priority = 0;
              target = "smtp.migadu.com";
              weight = 1;
            };
            name = "_submissions.${proto}.${name}";
            priority = 0;
            ttl = 1;
            type = "SRV";
          };

          imap = {
            inherit tags zone_id;
            comment = "IMAP incoming";
            data = {
              inherit name proto;
              port = 993;
              priority = 0;
              target = "imap.migadu.com";
              weight = 1;
            };
            name = "_imaps.${proto}.${name}";
            priority = 0;
            ttl = 1;
            type = "SRV";
          };

          pop = {
            inherit tags zone_id;
            comment = "POP3 incoming";
            data = {
              inherit name proto;
              port = 995;
              priority = 0;
              target = "pop.migadu.com";
              weight = 1;
            };
            name = "_pop3s.${proto}.${name}";
            priority = 0;
            ttl = 1;
            type = "SRV";
          };
        };
    in
    l.pipe records [
      (l.mapAttrs (
        name:
        l.mapAttrs' (
          name': l.nameValuePair "${slug}${if name != "others" then "_" + name else ""}_${name'}"
        )
      ))
      l.attrValues
      (l.foldl' l.mergeAttrs { })
    ];
in
{
  options.migadu = {
    domains = l.mkOption {
      description = "Domains where Migadu-hosted mailboxes are available";
      type = domainsSubmodule;
    };
  };

  config = {
    data.terraform_remote_state.networking = my.terraformRemoteState {
      modules = [ ../../networking/config.nix ];
    };

    resource.cloudflare_dns_record =
      let
        domains = with cfg.domains; [ primary ] ++ aliases;
      in
      l.pipe domains [
        (l.map dnsRecordsFor)
        (l.foldl' l.mergeAttrs { })
      ];
  };
}
