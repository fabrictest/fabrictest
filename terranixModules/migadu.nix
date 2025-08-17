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

  my = import ../../my pkgs;

  asSlug = replaceString "." "_";

  pipeThru = ops: data: pipe data ops;

  slugify = domainName: localPart: asSlug "${domainName}.${localPart}";

  emailify = domainName: localPart: "${localPart}@${domainName}";

  dnsRecordsFor =
    name:
    {
      verify,
      alias ? false,
      ...
    }:
    let
      slug = asSlug name;

      zone_id = tfRef "cloudflare_zone.${slug}.id";

      proto = "_tcp";

      records.mx =
        my.mapCartesianProductToAttrs
          (
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
          )
          {
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
            server = [
              "1"
              "2"
            ];
          };

      records.dkim =
        my.mapCartesianProductToAttrs
          (
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
          )
          {
            server = [
              "1"
              "2"
              "3"
            ];
          };

      records.others = {
        verification = {
          inherit zone_id name;
          type = "TXT";
          content = ''"hosted-email-verify=${verify}"'';
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
      (mapAttrs' (type: nameValuePair (if type == "others" then "" else "${type}_")))
      (mapAttrsToList (type_: mapAttrs' (name: nameValuePair "${slug}_${type_}${name}")))
      mergeAttrsList
    ];
in
{
  options = {
    migadu = mkOption {
      type = submodule {
        options = {
          domains = mkOption {
            type = nullOr (
              attrsOf (submodule {
                options = {
                  verify = mkOption {
                    description = "TODO TODO TODO TODO TODO";
                    type = str;
                    example = "abcdefgh";
                  };
                  aliases = mkOption {
                    type = attrsOf (submodule {
                      options = {
                        verify = mkOption {
                          description = "TODO TODO TODO TODO TODO";
                          type = str;
                          example = "abcdefgh";
                        };
                        alias = mkOption {
                          type = bool;
                          default = true;
                          internal = true;
                          visible = false;
                        };
                      };
                    });
                    default = { };
                  };
                  mailboxes = mkOption {
                    type = attrsOf (submodule {
                      options = {
                        name = mkOption {
                          description = "TODO TODO TODO TODO TODO";
                          type = str;
                          example = "Bender Bending Rodriguez";
                        };
                        admin = mkOption {
                          description = "Whether this mailbox belongs to an administrator of this service.";
                          type = bool;
                          default = false;
                          example = true;
                        };
                      };
                    });
                    default = { };
                  };
                };
              })
            );
            default = { };
          };
        };
      };
    };
  };

  imports = [
    ./provider/cloudflare.nix
    ./provider/migadu.nix
  ];

  config = {
    data = {
      terraform_remote_state = my.terraformRemoteStates [ "accounts/cloudflare" ];
    };
    resource = rec {
      cloudflare_zone =
        let
          allDomainNames = pipe cfg.domains [
            attrValues
            (map (v: v.aliases))
            (concat [ cfg.domains ])
            (map attrNames)
            flatten
          ];
        in
        my.mapToAttrs (
          name:
          nameValuePair (asSlug name) {
            account = {
              id = tfRef "data.terraform_remote_state.accounts_cloudflare.outputs.id";
            };
            inherit name;
            type = "full";
          }
        ) allDomainNames;

      cloudflare_zone_dnssec = mapAttrs (slug: _: {
        zone_id = tfRef "cloudflare_zone.${slug}.id";
        status = "active";
      }) cloudflare_zone;

      cloudflare_dns_record = pipe cfg.domains [
        attrValues
        (map (v: v.aliases))
        (concat [ cfg.domains ])
        mergeAttrsList
        (mapAttrsToList dnsRecordsFor)
        mergeAttrsList
      ];

      migadu_mailbox = pipe cfg.domains [
        (mapAttrs (_: v: v.mailboxes))
        (mapAttrsToList (
          domain_name:
          mapAttrs' (
            local_part:
            { name, ... }:
            let
              slug = slugify domain_name local_part;
            in
            nameValuePair slug {
              inherit domain_name local_part name;
              password = tfRef "random_password.${slug}.result";
              may_access_imap = true;
              may_access_manage_sieve = true;
              may_access_pop3 = true;
              may_send = true;
              may_receive = true;
            }
          )
        ))
        mergeAttrsList
      ];

      random_password = mapAttrs (
        _:
        { domain_name, local_part, ... }:
        {
          keepers = {
            inherit domain_name local_part;
          };
          length = 64;
        }
      ) migadu_mailbox;

      migadu_alias =
        let
          standardAliases = [
            "abuse"
            "noc"
            "security"
            "postmaster"
            "webmaster"
          ];
          adminAliases = [ "admin" ];
          adminAddrs = pipe cfg.domains [
            (mapAttrs (_: v: v.mailboxes))
            (mapAttrs (
              domainName:
              pipeThru [
                (filterAttrs (_: v: v.admin))
                attrNames
                (map (emailify domainName))
              ]
            ))
          ];
        in
        pipe
          {
            domain_name = attrNames cfg.domains;
            local_part = standardAliases ++ adminAliases;
          }
          [
            cartesianProduct
            (filter (
              { local_part, domain_name }:
              !elem local_part adminAliases
              || (hasAttr domain_name adminAddrs && adminAddrs.${domain_name} != [ ])
            ))
            (my.mapToAttrs (
              { domain_name, local_part }@value:
              {
                name = slugify domain_name local_part;
                value = value // {
                  destinations =
                    if elem local_part adminAliases then
                      adminAddrs.${domain_name}
                    else
                      map (emailify domain_name) adminAliases;
                };
              }
            ))
          ];
    };

  };
}
