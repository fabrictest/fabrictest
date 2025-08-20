{
  description = "Fabric Test — tautologicc's darknet";

  # TODO(eff): Add fabrictest cache.
  nixConfig.extra-substituters = [
    "https://cache.clan.lol"
    "https://cache.thalheim.io"
    "https://devenv.cachix.org"
    "https://nix-community.cachix.org"
  ];

  nixConfig.extra-trusted-public-keys = [
    "cache.clan.lol-1:3KztgSAB5R1M+Dz7vzkBGzXdodizbgLXGXKXlcQLA28="
    "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

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

  # NOTE(eff): url is overridden in .envrc.
  inputs.devenv-root = {
    url = "file+file:///dev/null";
    flake = false;
  };

  inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
    inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  inputs.mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

  inputs.nix2container = {
    url = "github:nlewo/nix2container";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.systems = {
    url = "path:./flake.systems.nix";
    flake = false;
  };

  /*
    inputs.terranix = {
      url = "github:terranix/terranix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
  */

  outputs =
    inputs@{
      clan-core,
      devenv,
      devenv-root,
      flake-parts,
      nixpkgs,
      systems,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        imports = [
          clan-core.flakeModules.default
          devenv.flakeModules.default
        ];

        flake.clan = ./clan.nix;

        systems = import systems;

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
              devenv.root =
                let
                  root = readFile devenv-root.outPath;
                in
                mkIf (root != "") root;

              name = "fabrictest";

              enterShell = ''
                echo TODO
              '';

              enterTest = ''
                echo TODO
              '';

              overlays = [ ];

              # TODO(eff): Extract terranix devenv module.

              packages = with pkgs; [
                git
                (opentofu.withPlugins (p: [
                  p.cloudflare
                  p.migadu
                  p.random
                ]))
                terranix

                clan-core.packages.${system}.clan-cli

                # Zed
                nil
                nixd
              ];

              tasks = { };

              processes.terraform-backend-git = rec {
                exec = getExe pkgs.terraform-backend-git;
                process-compose = {
                  availability.restart = "on_failure";
                  shutdown.command = "${exec} stop";
                };
              };

              services = { };

              cachix.enable = true;
              cachix.push = "fabrictest";

              git-hooks.hooks.treefmt.enable = true;
              git-hooks.hooks.treefmt.settings.formatters = with pkgs; [
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

              # TODO(eff): Should we add linters to treefmt as well?

              git-hooks.hooks.actionlint.enable = true;

              git-hooks.hooks.editorconfig-checker.enable = true;

              git-hooks.hooks.shellcheck.enable = true;

              # TODO(eff): Add a new hook for zizmor.

              delta.enable = true;

              difftastic.enable = true;
            };
          };
      }
    );
}
