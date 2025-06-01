{
  pkgs,
  lib,
  ...
}:
let
  l = lib // builtins;
in
{
  enterShell = '''';

  packages = [
    pkgs.git
    pkgs.terranix
  ];

  #tasks

  languages.terraform = {
    enable = true;
  };

  processes.terraform-backend-git = rec {
    exec = l.getExe pkgs.terraform-backend-git;
    process-compose = {
      availability.restart = "on_failure";
      shutdown.command = "${exec} stop";
    };
  };

  #services

  cachix = {
    enable = true;
    push = "fabrictest";
  };

  git-hooks = {
    hooks.treefmt = {
      enable = true;
      settings.formatters = [
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

        # Ruby
        pkgs.rubocop

        # Shell
        pkgs.shfmt

        # TOML
        pkgs.taplo

        # YAML
        pkgs.yamlfmt
        pkgs.yamllint
      ];
    };

    # TODO(eff): Should we add linters to treefmt as well?

    hooks.actionlint = {
      enable = true;
    };

    hooks.editorconfig-checker = {
      enable = true;
    };

    hooks.shellcheck = {
      enable = true;
    };

    # TODO(eff): Add a new hook for zizmor.
  };

  enterTest = '''';

  overlays = [
    (_final: prev: {
      terraform = prev.opentofu.withPlugins (p: [
        p.cloudflare
        p.migadu
      ]);
    })
  ];

  apple.sdk = null;

  delta.enable = true;

  difftastic.enable = true;

  dotenv.enable = true;
}
