{ lib, ... }:
let

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

  # XXX(eff): This mailbox doesn't use tempPassword for historical reasons.
  resource.random_password.caixadecorre_io_emerson = {
    keepers.address =
      with resource.migadu_mailbox.caixadecorre_io_emerson;
      "${local_part}@${domain_name}";
    length = 64;
  };

  # m@caixadecorre.io -> emerson@caixadecorre.io
  resource.migadu_identity.caixadecorre_io_m = {
    domain_name = lib.tfRef "migadu_mailbox.caixadecorre_io_emerson.domain_name";
    local_part = lib.tfRef "migadu_mailbox.caixadecorre_io_emerson.local_part";
    name = lib.tfRef "migadu_mailbox.caixadecorre_io_emerson.name";
    identity = "m";
    password_use = "none";
    may_send = true;
    may_receive = true;
  };

  forwardTo =
    resourcePath: aliasName:
    let
      tfRef =
        prop:
        lib.pipe prop [
          lib.toList
          (lib.concat resourcePath)
          (lib.concatStringsSep ".")
          lib.tfRef
        ];
    in
    {
      domain_name = tfRef "domain_name";
      local_part = aliasName;
      destinations = [
        (tfRef "address")
      ];
    };

  forwardToM = forwardTo [
    "migadu_identity"
    "caixadecorre_io_m"
  ];

  resource.migadu_alias.caixadecorre_io_admin = forwardToM "admin";
  resource.migadu_alias.caixadecorre_io_abuse = forwardToM "abuse";
  resource.migadu_alias.caixadecorre_io_noc = forwardToM "noc";
  resource.migadu_alias.caixadecorre_io_security = forwardToM "security";
  resource.migadu_alias.caixadecorre_io_postmaster = forwardToM "postmaster";
  resource.migadu_alias.caixadecorre_io_webmaster = forwardToM "webmaster";

  # NOTE(eff): Migadu creates a folder for each plus-address by default. The
  # following rewrite rule disables this feature—all e-mails land into INBOX.
  plusToInbox =
    order_num:
    { local_part, domain_name, ... }:
    {
      name = "${local_part}: route messages sent to plus-addresses to the main inbox";
      inherit order_num domain_name;
      local_part_rule = "${local_part}+*";
      destinations = [
        (lib.tfRef "migadu_mailbox.${lib.replaceString "." "_" domain_name}_${local_part}.address")
      ];
    };

  resource.migadu_rewrite_rule.caixadecorre_io_plus2inbox_emerson = plusToInbox 1 resource.migadu_mailbox.caixadecorre_io_emerson;

  # caixa@decorre.io, the true admin
  resource.migadu_mailbox.decorre_io_caixa = {
    domain_name = "decorre.io";
    local_part = "caixa";
    name = "F. Emerson";
    password = lib.tfRef "random_password.decorre_io_caixa.result";
    may_send = true;
    may_receive = true;
    may_access_imap = true;
    may_access_pop3 = true;
    may_access_manage_sieve = true;
  };

  tempPassword =
    { domain_name, local_part, ... }:
    {
      keepers = {
        inherit domain_name local_part;
      };
      length = 64;
    };

  resource.random_password.decorre_io_caixa = tempPassword resource.migadu_mailbox.decorre_io_caixa;

  # caix@decorre.io -> caixa@decorre.io
  resource.migadu_identity.decorre_io_caix = {
    domain_name = lib.tfRef "migadu_mailbox.decorre_io_caixa.domain_name";
    local_part = lib.tfRef "migadu_mailbox.decorre_io_caixa.local_part";
    name = lib.tfRef "migadu_mailbox.decorre_io_caixa.name";
    identity = "caix";
    password_use = "none";
    may_send = true;
    may_receive = true;
  };

  forwardToCaixa = forwardTo [
    "migadu_mailbox"
    "decorre_io_caixa"
  ];

  resource.migadu_alias.decorre_io_admin = forwardToCaixa "admin";
  resource.migadu_alias.decorre_io_abuse = forwardToCaixa "abuse";
  resource.migadu_alias.decorre_io_noc = forwardToCaixa "noc";
  resource.migadu_alias.decorre_io_security = forwardToCaixa "security";
  resource.migadu_alias.decorre_io_postmaster = forwardToCaixa "postmaster";
  resource.migadu_alias.decorre_io_webmaster = forwardToCaixa "webmaster";

  resource.migadu_rewrite_rule.decorre_io_plus2inbox_caixa = plusToInbox 1 resource.migadu_mailbox.decorre_io_caixa;

in
{
  imports = [
    ../../modules/backend/git.nix
    ../../modules/providers/migadu.nix
  ];

  backend.git.state = "services/migadu/live";

  inherit resource;
}
