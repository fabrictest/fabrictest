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
    url = "github:clan-lol/clan-core";
    inputs.flake-parts.follows = "flake-parts";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.systems.follows = "systems";
  };

  inputs.devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
    # FIXME(eff): This construct is broken. https://github.com/DeterminateSystems/nix-src/issues/95
    # inputs.git-hooks.inputs.flake-parts.follows = "flake-parts";
  };

  inputs.devenv-root = {
    # NOTE(eff): url is overridden in .envrc.
    url = "file+file:///dev/null";
    flake = false;
  };

  inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
    inputs.nixpkgs-lib.follows = "nixpkgs";
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

      clan.meta = {
        name = "fabrictest";
        description = "tautologicc's homelab";
      };

      clan.inventory = {
        machines.snaz = {
          tags = [ ];
        };

        instances.admin = {
          roles.default.tags.all = { };
          # TODO(eff): Rotate SSH key.
          roles.default.settings.allowedUsers.tautologicc =
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEI496sUFzVECzwdbjWFPwEyGp8tA6OuXKS3qedUXRnF";
        };

        instances.snaz-user = {
          module.name = "users";
          roles.default.tags.all = { };
          roles.default.settings = {
            user = "tautologicc";
            group = [
              "wheel"
              "networkmanager"
              "video"
              "input"
            ];
          };
        };

        instances.zerotier = {
          roles.controller.machines.snaz = { };
          roles.peer.tags.all = { };
        };
      };

      clan.machines = { };

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

            enterShell = ''
              echo TODO
            '';

            enterTest = ''
              echo TODO
            '';

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

              # XXX(eff): Can we have clan-cli-full without all its dep baggage?
              clan-core.packages.${system}.clan-cli

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
