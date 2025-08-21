{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  devenv.root =
    let
      root = lib.readFile inputs.devenv-root.outPath;
    in
    lib.mkIf (root != "") root;

  name = "fabrictest";

  enterShell = ''
    echo TODO
  '';

  enterTest = ''
    echo TODO
  '';

  overlays = [ ];

  # TODO(eff): Extract terranix devenv module.

  packages = [
    pkgs.git
    (pkgs.opentofu.withPlugins (p: [
      p.cloudflare
      p.migadu
      p.random
    ]))
    pkgs.terranix

    inputs.clan-core.packages.${pkgs.system}.clan-cli

    # Zed
    pkgs.nil
    pkgs.nixd
  ];

  tasks = { };

  processes.terraform-backend-git = rec {
    exec = lib.getExe pkgs.terraform-backend-git;
    process-compose = {
      availability.restart = "on_failure";
      shutdown.command = "${exec} stop";
    };
  };

  services = { };

  cachix.enable = true;
  cachix.push = "fabrictest";

  git-hooks.hooks.treefmt.enable = true;
  git-hooks.hooks.treefmt.settings.formatters = [
    # *
    pkgs.keep-sorted

    # JSON
    pkgs.jsonfmt

    # Markdown
    pkgs.mdformat
    pkgs.mdsh

    # Nix
    pkgs.deadnix
    pkgs.nixfmt-rfc-style
    pkgs.statix

    # Shell
    pkgs.shfmt

    # TOML
    pkgs.taplo

    # YAML
    pkgs.yamlfmt
    pkgs.yamllint
  ];

  # TODO(eff): Should we add linters to treefmt as well?

  git-hooks.hooks.actionlint.enable = true;

  git-hooks.hooks.editorconfig-checker.enable = true;

  git-hooks.hooks.shellcheck.enable = true;

  # TODO(eff): Add a new hook for zizmor.

  delta.enable = true;

  difftastic.enable = true;
}
