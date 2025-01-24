# https://treefmt.com
let
  inherit (inputs) l std;
  inherit (cell) pkgs;
in
std.lib.dev.mkNixago {

  output = "treefmt.toml";

  commands = [
    { package = pkgs.treefmt; }
  ];

  data = {
    global.excludes = [
      "*.diff"
      "*.patch"
      "*flake.lock"
    ];

    # *
    formatter = {

      # https://waterlan.home.xs4all.nl/dos2unix.html
      dos2unix =
        let
          command = l.getExe' pkgs.dos2unix "dos2unix";
          options = l.cli.toGNUCommandLine { } {
            add-eol = true;
            keepdate = true;
          };

          # NOTE(ttlgcc): By default, `dos2unix` formats files in-place.
          #  However, running it this way gives a lot of file permission
          #  errors.  Allow `dos2unix` to store partially formatted text
          #  in temporary files.
          dos2unix' = pkgs.writeShellScriptBin "dos2unix-newfile" ''
            printf %s\\n "''$@" |
              xargs -I{} -L1 -- printf ' --newfile "%s" "%s"' {} {} |
              xargs -- ${command} ${l.toString options}
          '';
        in
        {
          command = l.getExe dos2unix';
          includes = [ "*" ];
          priority = -10;
        };

      # https://github.com/google/keep-sorted
      keep-sorted = {
        command = l.getExe pkgs.keep-sorted;
        includes = [ "*" ];
        priority = 10;
      };
    };

    # Bash
    formatter = {

      # https://www.shellcheck.net/wiki/Home
      shellcheck = {
        command = l.getExe pkgs.shellcheck;
        includes = [
          "*.bash"
          "*.envrc"
          "*.envrc.*"
          "*.sh"
        ];
        priority = 1;
      };

      # https://github.com/mvdan/sh#shfmt
      shfmt = {
        command = l.getExe pkgs.shfmt;
        options = l.cli.toGNUCommandLine { } {
          simplify = true;
          write = true;
        };
        includes = [
          "*.bash"
          "*.envrc"
          "*.envrc.*"
          "*.sh"
        ];
      };
    };

    # JSON
    formatter = {

      # https://github.com/caarlos0/jsonfmt
      jsonfmt = {
        command = l.getExe pkgs.jsonfmt;
        options = l.cli.toGNUCommandLine { } {
          w = true;
        };
        includes = [ "*.json" ];
      };
    };

    # Markdown
    formatter = {

      # https://zimbatm.github.io/mdsh/
      mdsh = {
        command = l.getExe pkgs.mdsh;
        options = l.cli.toGNUCommandLine { } {
          inputs = true;
        };
        includes = [ "README.md" ];
        priority = -1;
      };

      # https://mdformat.readthedocs.io
      # FIXME(ttlgcc): Install plugins.
      mdformat = {
        command = l.getExe pkgs.python3Packages.mdformat;
        includes = [ "*.md" ];
      };
    };

    # Nix
    formatter = {

      # https://github.com/astro/deadnix
      deadnix = {
        command = l.getExe pkgs.deadnix;
        options = l.cli.toGNUCommandLine { } {
          edit = true;
        };
        includes = [ "*.nix" ];
        priority = -1;
      };

      # https://github.com/NixOS/nixfmt
      nixfmt = {
        command = l.getExe pkgs.nixfmt-rfc-style;
        includes = [ "*.nix" ];
      };

      # https://git.peppe.rs/languages/statix/about/
      statix =
        let
          inherit (cell.settings.statix) __passthru configFile;
          command = l.getExe (l.head __passthru.packages);
          options = l.cli.toGNUCommandLine { } {
            config = configFile;
          };

          # NOTE(ttlgcc): statix doesn't support fixing multiple files at once,
          #  so we fix them one by one.
          statix-fix = pkgs.writeShellScriptBin "statix-fix" ''
            for file in "''$@"
            do
              ${command} fix ${l.toString options} "''$file"
            done
          '';
        in
        {
          command = l.getExe statix-fix;
          includes = [ "*.nix" ];
          priority = 1;
        };
    };

    # Ruby
    formatter = {

      # https://docs.rubocop.org
      rubocop = {
        command = l.getExe pkgs.rubocop;
        includes = [ "*Brewfile" ];
      };
    };

    # YAML
    formatter = {

      # https://github.com/google/yamlfmt/
      yamlfmt =
        let
          inherit (cell.settings.yamlfmt) __passthru configFile;
        in
        {
          command = l.getExe (l.head __passthru.packages);
          options = l.cli.toGNUCommandLine { } {
            conf = configFile;
          };
          includes = [ "*.yaml" ];
        };
    };
  };
}
