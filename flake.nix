{
  description = "Fabric Test — F.'s homelab";

  nixConfig = {
    # TODO(eff): Add fabrictest cache.
    extra-substituters = [
      "https://cache.clan.lol"
      "https://cache.thalheim.io"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.clan.lol-1:3KztgSAB5R1M+Dz7vzkBGzXdodizbgLXGXKXlcQLA28="
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    clan-core = {
      url = "github:clan-lol/clan-core";
      inputs = {
        flake-parts = {
          follows = "flake-parts";
        };
        nixpkgs = {
          follows = "nixpkgs";
        };
        systems = {
          follows = "systems";
        };
      };
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        # FIXME(eff): This construct is broken. https://github.com/DeterminateSystems/nix-src/issues/95
        # git-hooks.inputs.flake-parts.follows = "flake-parts";
      };
    };

    devenv-root = {
      # NOTE(eff): url is overridden in .envrc.
      url = "file+file:///dev/null";
      flake = false;
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs = {
        nixpkgs-lib = {
          follows = "nixpkgs";
        };
      };
    };

    mk-shell-bin = {
      url = "github:rrbutani/nix-mk-shell-bin";
    };

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };

    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    systems = {
      url = "path:./flake.systems.nix";
      flake = false;
    };
  };

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
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        clan-core.flakeModules.default
        devenv.flakeModules.default
      ];

      systems = import systems;

      clan = {
        meta = {
          name = "fabrictest";
          description = "F.'s homelab";
        };

        inventory = {
          machines = {
            snaz = {
              deploy = {
                targetHost = "root@192.168.100.173";
              };
              # TODO(eff): Define tags.
              tags = [ ];
            };
          };

          instances = {
            admin = {
              roles = {
                default = {
                  tags = {
                    all = { };
                  };
                  settings = {
                    allowedKeys = {
                      eff = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONucbKwW3mhpLJmWpl2Z9oEH13jldnCeopjwn4u4koV";
                    };
                  };
                };
              };
            };

            snaz-user = {
              module = {
                input = "clan-core";
                name = "users";
              };

              roles = {
                default = {
                  tags = {
                    all = { };
                  };

                  settings = {
                    user = "eff";
                    groups = [
                      "wheel"
                      "networkmanager"
                      "video"
                      "input"
                    ];
                  };

                  extraModules = [
                    ./users/eff/home.nix
                  ];
                };
              };
            };

            zerotier = {
              roles = {
                controller = {
                  machines = {
                    snaz = { };
                  };
                };
                peer = {
                  tags = {
                    all = { };
                  };
                };
              };
            };
          };
        };
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
          _module = {
            args = {
              pkgs = import nixpkgs {
                inherit system;
                config = {
                  allowUnfree = true;
                };
              };
            };
          };

          devenv = {
            shells = {
              default = {
                devenv = {
                  root =
                    let
                      root = readFile devenv-root.outPath;
                    in
                    mkIf (root != "") root;
                };

                name = "fabrictest";

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

                tasks = { };

                processes = {
                  terraform-backend-git =
                    let
                      exec = getExe pkgs.terraform-backend-git;
                    in
                    {
                      inherit exec;
                      process-compose = {
                        availability = {
                          restart = "on_failure";
                        };
                        shutdown = {
                          command = "${exec} stop";
                        };
                      };
                    };
                };

                services = { };

                cachix = {
                  enable = true;
                  push = "fabrictest";
                };

                git-hooks = {
                  hooks = {
                    treefmt = {
                      enable = true;
                      settings = {
                        formatters = with pkgs; [
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
                    };

                    # TODO(eff): Should we add linters to treefmt as well?

                    actionlint = {
                      enable = true;
                    };

                    editorconfig-checker = {
                      enable = true;
                    };

                    shellcheck = {
                      enable = true;
                    };

                    # TODO(eff): Add a new hook for zizmor.
                  };
                };

                delta = {
                  enable = true;
                };

                difftastic = {
                  enable = true;
                };
              };
            };
          };
        };

      flake = {

      };
    };
}
