# https://editorconfig.org
let
  inherit (inputs) l std;
  inherit (cell) pkgs;
in
std.lib.dev.mkNixago {

  output = ".editorconfig";

  engine =
    request:
    let
      inherit (request) data output;
      name = l.baseNameOf output;
      value = {
        globalSection.root = true;
        sections = data;
      };
    in
    pkgs.writeText name (l.generators.toINIWithGlobalSection { } value);

  packages = [
    pkgs.editorconfig-checker
  ];

  data = {
    "*" = {
      charset = "utf-8";
      end_of_line = "lf";
      indent_size = 8;
      indent_style = "tab";
      insert_final_newline = true;
      trim_trailing_whitespace = true;
    };

    "{*.diff,*.patch,flake.lock}" = {
      end_of_line = "unset";
      indent_size = "unset";
      indent_style = "unset";
      insert_final_newline = "unset";
      trim_trailing_whitespace = "unset";
    };

    "*.json" = {
      indent_size = 2;
      indent_style = "space";
    };

    "*.md" = {
      indent_size = 2;
      indent_style = "space";
      trim_trailing_whitespace = false;
    };

    "*.nix" = {
      indent_size = 2;
      indent_style = "space";
    };

    "{*.yaml,*.yml}" = {
      indent_size = 2;
      indent_style = "space";
    };
  };
}
