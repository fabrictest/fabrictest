{
  description = "fabricte.st - eff's homelab";

  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    devenv.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    devenv-root.url = "file+file:///dev/null";
    devenv-root.flake = false;
  };

  nixConfig = {
    # TODO(eff): Add fabrictest cache.
    extra-substituters = [
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModules.default
      ];

      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem =
        { config, system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          devenv.shells.default = {
            name = "fabrictest";

            # TODO(eff): Inline module.
            imports = [ ./devenv.nix ];
          };

        };
    };
}
