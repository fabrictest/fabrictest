{ lib, pkgs, ... }:
let
  l = lib // builtins;

  my = import ../my { inherit pkgs; };
in
{
  imports = [
    ../modules/backend/git
    ../modules/providers/cloudflare
  ];

  backend.git.path = "networking/live";

  data.terraform_remote_state.cloudflare = my.terraformRemoteState {
    modules = [ ../accounts/cloudflare/config.nix ];
  };

  #

  # fabricte.st
  resource = {
    cloudflare_zone.fabricte_st = {
      account.id = l.tfRef "data.terraform_remote_state.cloudflare.outputs.account_id";
      name = "fabricte.st";
      type = "full";
    };

    cloudflare_zone_dns_settings.fabricte_st = {
      zone_id = l.tfRef "cloudflare_zone.bricte_st.id";
      nameservers.type = "cloudflare.standard";
    };

    cloudflare_zone_dnssec.fabricte_st = {
      zone_id = l.tfRef "cloudflare_zone.fabricte_st.id";
      status = "active";
    };

    cloudflare_dns_record.github_fabrictest_domain_fabricte_st = {
      zone_id = l.tfRef "cloudflare_zone.fabricte_st.id";
      comment = "Verification record for GitHub organization `fabrictest`";
      content = ''"0d5297bb10"'';
      name = "_gh-fabrictest-o";
      settings.flatten_cname = true;
      tags = [ ];
      ttl = 1;
      type = "TXT";
    };
  };

  #

  # bricte.st
  resource = {
    cloudflare_zone.bricte_st = {
      account.id = l.tfRef "data.terraform_remote_state.cloudflare.outputs.account_id";
      name = "bricte.st";
    };

    cloudflare_zone_dns_settings.bricte_st = {
      zone_id = l.tfRef "cloudflare_zone.bricte_st.id";
      nameservers.type = "cloudflare.standard";
    };

    cloudflare_zone_dnssec.bricte_st = {
      zone_id = l.tfRef "cloudflare_zone.bricte_st.id";
      status = "active";
    };

    cloudflare_dns_record.github_fabrictest_domain_bricte_st = {
      zone_id = l.tfRef "cloudflare_zone.bricte_st.id";
      comment = "Verification record for GitHub organization `fabrictest`";
      name = "_gh-fabrictest-o";
      content = ''"424247d46b"'';
      settings.flatten_cname = true;
      tags = [ ];
      ttl = 1;
      type = "TXT";
    };
  };

  #

  output = {
    fabricte_st_zone_id.value = l.tfRef "cloudflare_zone.fabricte_st.id";
    fabricte_st_zone_name.value = l.tfRef "cloudflare_zone.fabricte_st.name";

    bricte_st_zone_id.value = l.tfRef "cloudflare_zone.bricte_st.id";
    bricte_st_zone_name.value = l.tfRef "cloudflare_zone.bricte_st.name";
  };

}
