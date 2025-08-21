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

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        imports = [
          inputs.clan-core.flakeModules.default
          inputs.devenv.flakeModules.default
        ];

        clan = ./clan.nix;

        systems = import inputs.systems;

        perSystem =
          { system, ... }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

            devenv.shells.default = ./devenv.nix;
          };
      }
    );
}
