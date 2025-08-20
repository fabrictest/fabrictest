{
  config,
  lib,
  ...
}:
let
  cfg = config.migadu;

  standardAliases = [
    "abuse"
    "noc"
    "security"
    "postmaster"
    "webmaster"
  ];

  adminAliases = [ "admin" ];

  adminAddrs = lib.mapAttrs (
    domain:
    { mailbox, ... }:
    lib.pipe mailbox [
      (lib.filterAttrs (_: v: v.admin))
      lib.attrNames
      (lib.map (emailify domain))
    ]
  ) cfg.domain;

  slugify = lib.replaceString "." "_";

  slugify2 = domain: user: slugify "${domain}_${user}";

  emailify = domain: user: "${user}@${domain}";

  dnsRecordsFor =
    name:
    {
      verification,
      _alias ? false,
      ...
    }:
    let
      slug = slugify name;

      zone_id = lib.tfRef "cloudflare_zone.${slug}.id";

      proto = "_tcp";

      records.mx =
        lib.pipe
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
          }
          [
            (lib.mapCartesianProduct (
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
            (lib.mapCartesianProduct (
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
            lib.listToAttrs
          ];

      records.others = {
        verification = {
          inherit zone_id name;
          type = "TXT";
          content = ''"hosted-email-verify=${verification}"'';
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
      // lib.optionalAttrs (!_alias) {
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
      (lib.mapAttrs' (type: lib.nameValuePair (if type == "others" then "" else "${type}_")))
      (lib.mapAttrsToList (type_: lib.mapAttrs' (name: lib.nameValuePair "${slug}_${type_}${name}")))
      lib.mergeAttrsList
    ];

  domainModule =
    {
      alias ? false,
    }:
    {
      options = {
        verification = lib.mkOption {
          description = "TODO TODO TODO TODO TODO";
          type = lib.types.strMatching ''[a-z0-9]{8}'';
          example = "abcdefgh";
        };
        _alias = lib.mkOption {
          default = alias;
          internal = true;
          visible = false;
          readOnly = true;
        };
      }
      // lib.optionalAttrs (!alias) {
        alias = lib.mkOption {
          description = "TODO";
          type = lib.types.attrsOf (
            lib.types.submodule (domainModule {
              alias = true;
            })
          );
          default = { };
        };
        mailbox = lib.mkOption {
          description = "TODO";
          type = lib.types.attrsOf (lib.types.submodule mailboxModule);
          default = { };
        };
      };
    };

  mailboxModule = {
    options.name = lib.mkOption {
      description = "TODO";
      type = lib.types.nonEmptyStr;
      example = "Bender Bending Rodriguez";
    };
    options.admin = lib.mkOption {
      description = ''
        Whether this mailbox belongs to an administrator of this service.
      '';
      type = lib.types.bool;
      default = false;
      example = true;
    };
  };

  mkIfEnabled = lib.mkIf cfg.enable;
in
{
  options.migadu = lib.mkOption {
    description = "TODO";
    type = lib.types.submodule (
      { config, ... }:
      {
        options.domain = lib.mkOption {
          description = "TODO";
          type = lib.types.attrsOf (lib.types.submodule (domainModule { }));
          default = { };
        };
        options.enable = lib.mkOption {
          description = "TODO";
          type = lib.types.bool;
          readOnly = true;
          default = config.domain != { };
        };
        options._domain = lib.mkOption {
          internal = true;
          visible = false;
          default = config.domain;
          apply =
            domain:
            lib.pipe domain [
              (lib.mapAttrsToList (_: v: v.alias))
              (lib.concat [ domain ])
              lib.mergeAttrsList
            ];
        };
      }
    );
    default = { };
  };

  config.tf.provider = lib.genAttrs [ "cloudflare" "migadu" ] (_: {
    enable = lib.mkDefault cfg.enable;
  });

  config.resource.cloudflare_zone = mkIfEnabled (
    lib.mapAttrs' (name: _: {
      name = slugify name;
      value.account.id = config.tf.remote_state.accounts_cloudflare.output.id;
      value.name = name;
      value.type = "full";
    }) cfg._domain
  );

  config.resource.cloudflare_zone_dnssec = mkIfEnabled (
    lib.pipe cfg._domain [
      lib.attrNames
      (lib.map slugify)
      (lib.flip lib.genAttrs (slug: {
        zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
        status = "active";
      }))
    ]
  );

  config.resource.cloudflare_dns_record = mkIfEnabled (
    lib.pipe cfg._domain [
      (lib.mapAttrsToList dnsRecordsFor)
      lib.mergeAttrsList
    ]
  );

  config.resource.migadu_mailbox = mkIfEnabled (
    lib.pipe cfg.domain [
      (lib.mapAttrs (_: v: v.mailbox))
      (lib.mapAttrsToList (
        domain:
        lib.mapAttrs' (
          user:
          { name, ... }:
          let
            slug = slugify2 domain user;
          in
          lib.nameValuePair slug {
            domain_name = domain;
            local_part = user;
            inherit name;
            password = lib.tfRef "random_password.${slug}.result";
            may_access_imap = true;
            may_access_manage_sieve = true;
            may_access_pop3 = true;
            may_send = true;
            may_receive = true;
          }
        )
      ))
      lib.mergeAttrsList
    ]
  );

  config.resource.random_password = mkIfEnabled (
    lib.pipe cfg.domain [
      (lib.mapAttrs (_: v: v.mailbox))
      (lib.mapAttrsToList (
        domain:
        lib.mapAttrs' (
          user: _: {
            name = slugify2 domain user;
            value.keepers.domain_name = domain;
            value.keepers.local_part = user;
            value.length = 64;
          }
        )
      ))
      lib.mergeAttrsList
    ]
  );

  config.resource.migadu_alias = mkIfEnabled (
    lib.pipe
      {
        domain = lib.attrNames cfg.domain;
        alias = standardAliases ++ adminAliases;
      }
      [
        lib.cartesianProduct
        (lib.filter ({ domain, alias }: !lib.elem alias adminAliases || adminAddrs.${domain} != [ ]))
        (lib.map (
          { domain, alias }:
          {
            name = slugify2 domain alias;
            value.domain_name = domain;
            value.local_part = alias;
            value.destinations =
              if lib.elem alias adminAliases then
                adminAddrs.${domain}
              else
                lib.map (emailify domain) adminAliases;
          }
        ))
        lib.listToAttrs
      ]
  );
}
