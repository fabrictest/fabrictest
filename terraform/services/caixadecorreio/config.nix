{ lib, pkgs, ... }:
with lib;
let

  my = import ../../my pkgs;

  mailboxes = pipe ./mailboxes.nix [
    import
    (concat [
      {
        # caixa@decorre.io - the true admin
        name = "F. Emerson";
        local_part = "caixa";
        domain_name = "decorre.io";
      }
    ])
    (map (mergeAttrs {
      domain_name = "caixadecorre.io";
      may_access_imap = true;
      may_access_manage_sieve = true;
      may_access_pop3 = true;
      may_send = true;
      may_receive = true;
    }))
  ];

  resource.migadu_mailbox = my.mapToAttrs (
    { domain_name, local_part, ... }@mailbox:
    let
      resourceId = "${replaceString "." "_" domain_name}_${local_part}";
      resource = mailbox // {
        password = tfRef "random_password.${resourceId}.result";
      };
    in
    nameValuePair resourceId resource
  ) mailboxes;

  resource.random_password = mapAttrs (
    _:
    { domain_name, local_part, ... }:
    {
      keepers = {
        inherit domain_name local_part;
      };
      length = 64;
    }
  ) resource.migadu_mailbox;

  # m@caixadecorre.io -> emerson@caixadecorre.io
  resource.migadu_identity.caixadecorre_io_m =
    let
      resource = "migadu_mailbox.caixadecorre_io_emerson";
    in
    {
      identity = "m";
      domain_name = tfRef "${resource}.domain_name";
      local_part = tfRef "${resource}.local_part";
      name = tfRef "${resource}.name";
      password_use = "none";
      may_send = true;
      may_receive = true;
    };

  # FIXME(eff): The resources below must be refactored into a format similar to
  # the above. They're good enough as they are, and I don't expect to set up
  # aliases or identities externally, so we aren't touching them yet.

  # caix@decorre.io -> caixa@decorre.io
  resource.migadu_identity.decorre_io_caix =
    let
      resource = "migadu_mailbox.decorre_io_caixa";
    in
    {
      identity = "caix";
      domain_name = tfRef "${resource}.domain_name";
      local_part = tfRef "${resource}.local_part";
      name = tfRef "${resource}.name";
      password_use = "none";
      may_send = true;
      may_receive = true;
    };

  forwardTo = resource: local_part: {
    domain_name = tfRef "${resource}.domain_name";
    inherit local_part;
    destinations = [ (tfRef "${resource}.address") ];
  };

  forwardToM = forwardTo "migadu_mailbox.caixadecorre_io_emerson";
  resource.migadu_alias.caixadecorre_io_admin = forwardToM "admin";

  forwardToCaixa = forwardTo "migadu_mailbox.decorre_io_caixa";
  resource.migadu_alias.decorre_io_admin = forwardToCaixa "admin";

  # NOTE(eff): Migadu creates a folder for each plus-address by default. The
  # following rewrite rule disables this feature—all e-mails land into INBOX.
  plus2inbox =
    order_num: resource:
    let
      outputRef = output: tfRef "${resource}.${output}";
      domain_name = outputRef "domain_name";
      local_part = outputRef "local_part";
      identity = outputRef (if hasPrefix "migadu_identity." resource then "identity" else "local_part");
    in
    {
      name = "${identity}: route messages sent to plus-addresses to the main inbox";
      inherit order_num domain_name;
      local_part_rule = "${identity}+*";
      destinations = [
        "${local_part}@${domain_name}"
      ];
    };

  resource.migadu_rewrite_rule.caixadecorre_io_plus2inbox_emerson = plus2inbox 1 "migadu_mailbox.caixadecorre_io_emerson";
  resource.migadu_rewrite_rule.caixadecorre_io_plus2inbox_m = plus2inbox 2 "migadu_identity.caixadecorre_io_m";

  resource.migadu_rewrite_rule.decorre_io_plus2inbox_caixa = plus2inbox 1 "migadu_mailbox.decorre_io_caixa";
in
{
  imports = [
    ../../modules/backend/git.nix
    ../../modules/providers/migadu.nix
  ];

  backend.git.state = "services/migadu/live";

  inherit resource;
}
