{
  pkgs,
  lib,
  ...
}:
let
  l = lib // builtins;
in
{
  enterShell = ''
    test -n "''${CI+x}" ||
    ${l.getExe' pkgs.cowsay "cowsay"} 'Welcome to Fabric Test. devenv(1) is your friend.'
  '';

  packages = [
    pkgs.git
    pkgs.terranix
  ];

  languages.terraform = {
    enable = true;
  };

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
}
