# https://github.com/google/yamlfmt/
let
  inherit (inputs) std;
  inherit (cell) pkgs;
in
std.lib.dev.mkNixago {

  output = "yamlfmt.yaml";

  packages = [
    pkgs.yamlfmt
  ];

  data = {
    line_ending = "lf";
    gitignore_excludes = true;
    formatter = {
      type = "basic";
      include_document_start = true;
      scan_folded_as_literal = true;
      trim_trailing_whitespace = true;
      eof_newline = true;
    };
  };
}
