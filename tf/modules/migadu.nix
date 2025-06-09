{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.migadu;

  data.terraform_remote_state.network = my.tfRemoteState ../network/config.nix;

  my = import ../lib { inherit pkgs; };

  dnsRecordsFor =
    {
      name,
      verify,
      primary,
      tags,
    }:
    let
      slug = lib.replaceString "." "_" name;
      zone_id = lib.tfRef "data.terraform_remote_state.network.outputs.zone_${slug}_id";

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
            (lib.map (
              { record, server }:
              lib.nameValuePair "${server}_${record.type}" {
                inherit tags zone_id;
                inherit (record) name;
                comment = "Mail eXchanger host #${server} (${record.type})";
                content = "aspmx${server}.migadu.com";
                priority = 10 * (lib.toInt server);
                ttl = 1;
                type = "MX";
              }
            ))
            lib.listToAttrs
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
            (lib.map (
              { server }:
              lib.nameValuePair server {
                inherit tags zone_id;
                type = "CNAME";
                name = "key${server}._domainkey.${name}";
                content = "key${server}.${name}._domainkey.migadu.com";
                ttl = 1;
                proxied = false;
                comment = "DKIM+ARC key #${server}";
              }
            ))
            lib.listToAttrs
          ];

      records.others =
        {
          verification = {
            inherit tags zone_id name;
            type = "TXT";
            content = ''"hosted-email-verify=${verify}"'';
            ttl = 1;
            comment = "Migadu verification record";
          };

          spf = {
            inherit tags zone_id name;
            type = "TXT";
            content = ''"v=spf1 include:spf.migadu.com -all"'';
            ttl = 1;
            comment = "SPF record";
          };

          dmarc = {
            inherit tags zone_id;
            name = "_dmarc.${name}";
            type = "TXT";
            content = ''"v=DMARC1; p=quarantine;"'';
            ttl = 1;
            comment = "DMARC policy";
          };
        }
        // lib.optionalAttrs primary {
          autoconfig = {
            inherit tags zone_id;
            type = "CNAME";
            name = "autoconfig.${name}";
            content = "autoconfig.migadu.com";
            ttl = 1;
            proxied = false;
            comment = "Thunderbird autoconfig mechanism";
          };

          autodiscover = {
            inherit tags zone_id;
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
            inherit tags zone_id;
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
            inherit tags zone_id;
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
            inherit tags zone_id;
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

  domainSubmodule =
    {
      primary ? false,
    }:
    lib.types.submodule {
      options.name = lib.mkOption {
        description = "Name of the DNS zone";
        type = lib.types.str;
      };

      options.verify = lib.mkOption {
        description = "Token used for DNS verification on the Migadu side";
        type = lib.types.str;
      };

      options.primary = lib.mkOption {
        default = primary;
        internal = true;
        readOnly = true;
      };
    };
in
{
  imports = [
    ./providers/cloudflare
  ];

  options.migadu.domain = lib.mkOption {
    description = "Domains where mailboxes are available";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.primary = lib.mkOption {
          type = domainSubmodule { primary = true; };
        };

        options.aliases = lib.mkOption {
          type = lib.types.listOf (domainSubmodule { });
          default = [ ];
        };

        options.tags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      }
    );
  };

  config = {
    inherit data;

    resource.cloudflare_dns_record = lib.pipe cfg.domain [
      (lib.mapAttrsToList (
        _: d:
        lib.pipe
          [ d.primary ]
          [
            (lib.concat d.aliases)
            (lib.map (lib.mergeAttrs { inherit (d) tags; }))
          ]
      ))
      lib.flatten
      (lib.map dnsRecordsFor)
      (lib.foldl' lib.mergeAttrs { })
    ];
  };

}
