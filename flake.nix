{
  description = "Fabric Test - tautologicc's homelab";

  nixConfig = {
    # TODO(eff): Add fabrictest cache.
    extra-substituters = [
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  inputs.clan-core = {
    url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
    inputs.flake-parts.follows = "flake-parts";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.systems.follows = "systems";
  };

  inputs.devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.devenv-root = {
    url = "file+file:///dev/null";
    flake = false;
  };

  inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
  };

  inputs.nixpkgs = {
    url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  inputs.systems = {
    url = "path:./flake.systems.nix";
    flake = false;
  };

  outputs =
    inputs@{
      clan-core,
      devenv,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } rec {
      imports = [
        clan-core.flakeModules.default
        devenv.flakeModules.default
      ];

      systems = import inputs.systems;

      clan = {
        meta.name = "fabrictest";
      };

      perSystem =
        {
          lib,
          pkgs,
          system,
          ...
        }:
        with lib;
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          devenv.shells.default = {
            inherit (clan.meta) name;

            enterShell = '''';

            enterTest = '''';

            overlays = [ ];

            # TODO(eff): Extract terranix module.

            packages = with pkgs; [
              git
              (opentofu.withPlugins (p: [
                p.cloudflare
                p.migadu
                p.random
              ]))
              terranix

              # Zed
              nil
              nixd
            ];

            #tasks

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

            git-hooks.hooks.treefmt = {
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

            git-hooks.hooks.actionlint = {
              enable = true;
            };

            git-hooks.hooks.editorconfig-checker = {
              enable = true;
            };

            git-hooks.hooks.shellcheck = {
              enable = true;
            };

            # TODO(eff): Add a new hook for zizmor.

            apple.sdk = null;

            delta.enable = true;

            difftastic.enable = true;
          };
        };

      flake = {

      };
    };
}
