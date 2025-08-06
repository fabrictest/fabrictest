{
  pkgs,
  lib,
  ...
}:
with lib;
{
  enterShell = '''';

  packages = with pkgs; [
    git
    terranix

    # Zed
    nil
    nixd
  ];

  #tasks

  languages.terraform.enable = true;

  processes.terraform-backend-git = rec {
    exec = getExe pkgs.terraform-backend-git;
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
      settings.formatters = with pkgs; [
        # *
        keep-sorted

        # JSON
        jsonfmt

        # Markdown
        mdformat
        mdsh

        # Nix
        deadnix
        nixfmt-rfc-style
        statix

        # Shell
        shfmt

        # TOML
        taplo

        # YAML
        yamlfmt
        yamllint
      ];
    };

    # TODO(eff): Should we add linters to treefmt as well?

    hooks.actionlint.enable = true;

    hooks.editorconfig-checker.enable = true;

    hooks.shellcheck.enable = true;

    # TODO(eff): Add a new hook for zizmor.
  };

  enterTest = '''';

  overlays = [
    (_final: prev: {
      terraform = prev.opentofu.withPlugins (p: [
        p.cloudflare
        p.migadu
        p.random
      ]);
    })
  ];

  apple.sdk = null;

  delta.enable = true;

  difftastic.enable = true;

  # FIXME(eff): Doesn't seem to work with flakes anymore.
  dotenv.enable = true;
}
