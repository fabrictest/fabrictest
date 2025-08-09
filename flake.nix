{
  description = "F.'s homelab";

  nixConfig = {
    # TODO(eff): Add fabrictest cache.
    extra-substituters = [
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
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
                  # TODO(eff): Rotate SSH key.
                  settings = {
                    allowedUsers = rec {
                      tautologicc = eff;
                      eff = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEI496sUFzVECzwdbjWFPwEyGp8tA6OuXKS3qedUXRnF";
                    };
                  };
                };
              };
            };

            snaz-user = {
              module = {
                name = "users";
              };
              roles = {
                default = {
                  tags = {
                    all = { };
                  };
                  settings = {
                    user = "eff";
                    group = [
                      "wheel"
                      "networkmanager"
                      "video"
                      "input"
                    ];
                  };
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

        machines = {
          snaz = {
            nixpkgs = {
              hostPlatform = "x86_64-linux";
            };

            clan = {
              core = {
                networking = {
                  targetHost = "root@snaz";
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
