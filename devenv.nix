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
  };

  git-hooks = {
    hooks.treefmt = {
      enable = true;
      settings.formatters =
        let
          statix-fix = pkgs.writeShellApplication {
            name = "statix-fix";
            runtimeInputs = [ pkgs.statix ];
            text = ''
              for file in "''$@"; do
                statix fix "''$file"
              done
            '';
          };
        in
        [
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
          statix-fix

          # Ruby
          pkgs.rubocop

          # Shell
          pkgs.shfmt

          # TOML
          pkgs.taplo

          # YAML
          pkgs.actionlint # GitHub Actions
          pkgs.yamlfmt
          pkgs.yamllint
          pkgs.zizmor # GitHub Actions
        ];
    };

    # TODO(eff): Should we add linters to treefmt as well?

    hooks.editorconfig-checker = {
      enable = true;
    };

    hooks.shellcheck = {
      enable = true;
    };
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

  difftastic.enable = true;
}
