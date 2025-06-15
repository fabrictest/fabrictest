{ lib, pkgs, ... }:
let
  domains =
    my.mapToAttrs
      (value: {
        name = lib.replaceString "." "_" value.name;
        inherit value;
      })
      [
        {
          name = "caixadecorre.io";
          verify = "tloqjtbj";
          primary = true;
        }
        {
          name = "decorre.io";
          verify = "l9ax4axw";
        }
      ];

  my = import ../lib pkgs;

  modules = import ../mod;

  data.terraform_remote_state = my.tfRemoteStates [
    "acc_cloudflare"
    "net_fabrictest"
  ];

  resource.cloudflare_zone = lib.mapAttrs (
    _:
    { name, ... }:
    {
      account.id = lib.tfRef "data.terraform_remote_state.acc_cloudflare.outputs.id";
      inherit name;
      type = "full";
    }
  ) domains;

  resource.cloudflare_zone_dns_settings = lib.mapAttrs (slug: _: {
    zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
    nameservers.type = "cloudflare.standard";
  }) resource.cloudflare_zone;

  resource.cloudflare_zone_dnssec = lib.mapAttrs (slug: _: {
    zone_id = lib.tfRef "cloudflare_zone.${slug}.id";
    status = "active";
  }) resource.cloudflare_zone;

  dnsRecordsFor =
    slug:
    {
      name,
      verify,
      primary ? false,
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
            (lib.map (
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
            lib.cartesianProduct
            (lib.map (
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

      records.others =
        {
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
        // lib.optionalAttrs primary {
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

  # emerson@caixadecorre.io
  resource.migadu_mailbox.caixadecorre_io_emerson = {
    domain_name = "caixadecorre.io";
    local_part = "emerson";
    name = "F. Emerson";
    password = lib.tfRef "random_password.caixadecorre_io_emerson.result";
    may_access_imap = true;
    may_access_manage_sieve = true;
    may_access_pop3 = true;
    may_send = true;
    may_receive = true;
  };

  resource.random_password.caixadecorre_io_emerson = {
    keepers.address =
      with resource.migadu_mailbox.caixadecorre_io_emerson;
      "${local_part}@${domain_name}";
    length = 64;
  };

  # m@caixadecorre.io -> emerson@caixadecorre.io
  resource.migadu_identity.caixadecorre_io_m = {
    depends_on = [ "migadu_mailbox.caixadecorre_io_emerson" ];
    inherit (resource.migadu_mailbox.caixadecorre_io_emerson) domain_name local_part name;
    identity = "m";
    password_use = "none";
    may_send = true;
    may_receive = true;
  };

  # caix@decorre.io -> emerson@caixadecorre.io
  resource.migadu_identity.caixadecorre_io_caix = {
    depends_on = [ "migadu_mailbox.caixadecorre_io_emerson" ];
    inherit (resource.migadu_mailbox.caixadecorre_io_emerson) domain_name local_part name;
    identity = "caix";
    password_use = "none";
    may_send = true;
    may_receive = true;
  };

  # *@caixa.decorre.io -> emerson+*@caixadecorre.io
  resource.migadu_identity.caixadecorre_io_caixa = {
    depends_on = [ "migadu_mailbox.caixadecorre_io_emerson" ];
    inherit (resource.migadu_mailbox.caixadecorre_io_emerson) domain_name local_part name;
    identity = "caixa";
    password_use = "none";
    may_send = true;
    may_receive = true;
  };

in
{
  imports = [
    modules.backend.git
    modules.providers.cloudflare
    modules.providers.migadu
  ];

  backend.git.state = "services/migadu/live";

  inherit data resource;
}
