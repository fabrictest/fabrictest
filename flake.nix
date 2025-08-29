{
  description = "Fabric Test — tautologicc's darknet";

  # TODO(eff): Add fabrictest cache.
  nixConfig.extra-substituters = [
    "https://cache.clan.lol"
    "https://cache.thalheim.io"
    "https://cache.flakehub.com"
    "https://devenv.cachix.org"
    "https://nix-community.cachix.org"
  ];

  nixConfig.extra-trusted-public-keys = [
    "cache.clan.lol-1:3KztgSAB5R1M+Dz7vzkBGzXdodizbgLXGXKXlcQLA28="
    "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  inputs.clan-core.url = "github:clan-lol/clan-core";
  inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  inputs.devenv.url = "github:cachix/devenv";
  inputs.flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
  inputs.mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
  inputs.nix2container.url = "github:nlewo/nix2container";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";

  inputs.clan-core.inputs.flake-parts.follows = "flake-parts";
  inputs.clan-core.inputs.nixpkgs.follows = "nixpkgs";
  inputs.clan-core.inputs.systems.follows = "systems";

  inputs.determinate.inputs.nix.inputs.flake-parts.follows = "nixpkgs";
  inputs.determinate.inputs.nix.inputs.git-hooks-nix.follows = "devenv/git-hooks";
  inputs.determinate.inputs.nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.determinate.inputs.nixpkgs.follows = "nixpkgs";

  inputs.devenv.inputs.nixpkgs.follows = "nixpkgs";
  inputs.devenv.inputs.git-hooks.inputs.flake-parts.follows = "flake-parts";

  inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

  inputs.nix2container.inputs.nixpkgs.follows = "nixpkgs";

  # NOTE(eff): url is overridden in .envrc.
  inputs.devenv-root.url = "file+file:///dev/null";
  inputs.devenv-root.flake = false;

  inputs.systems.url = "path:./flake.systems.nix";
  inputs.systems.flake = false;

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
