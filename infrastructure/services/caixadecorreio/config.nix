{ lib, ... }:
let
  # NOTE(eff): Migadu creates a folder for each plus-address by default. The
  # following rewrite rule disables this feature—all e-mails land into INBOX.
  sendPlusToInbox =
    order_num: resource:
    let
      outputRef = output: lib.tfRef "${resource}.${output}";
      domain_name = outputRef "domain_name";
      local_part = outputRef "local_part";
      identity = outputRef (
        if lib.hasPrefix "migadu_identity." resource then "identity" else "local_part"
      );
    in
    {
      name = "${identity}: route messages from plus-addresses to INBOX";
      inherit order_num domain_name;
      local_part_rule = "${identity}+*";
      destinations = [
        "${local_part}@${domain_name}"
      ];
    };
in
{
  imports = [ ../../../terranixModules ];

  tf.backend.state = "networking/caixadecorreio";

  tf.remote_state.accounts_cloudflare.config = ../../accounts/cloudflare/config.nix;

  migadu.domain."caixadecorre.io" = {
    verification = "tloqjtbj";
    alias."ecorre.io".verification = "a8g9xgv4";
    mailbox = import ./mailboxes.nix;
  };

  # TODO(eff): I don't yet have a clear idea how to implement identities.
  # So for now, we're setting these resources not through the migadu module,
  # but directly through tofu constructs.

  # m@caixadecorre.io -> emerson@caixadecorre.io
  resource.migadu_identity.caixadecorre_io_m = {
    identity = "m";
    domain_name = "caixadecorre.io";
    local_part = "emerson";
    name = "F. Emerson";
    password_use = "none";
    may_send = true;
    may_receive = true;
  };

  resource.migadu_rewrite_rule.caixadecorre_io_plus2inbox_m = sendPlusToInbox 1 "migadu_identity.caixadecorre_io_m";
  resource.migadu_rewrite_rule.caixadecorre_io_plus2inbox_emerson = sendPlusToInbox 2 "migadu_mailbox.caixadecorre_io_emerson";
}
