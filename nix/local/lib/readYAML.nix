let
  inherit (inputs) l;
  inherit (cell) pkgs;

  yaml2json =
    path:
    pkgs.runCommand "yaml2json" { nativeBuildInputs = [ pkgs.remarshal ]; } ''
      yaml2json <"${path}" >"''$out"
    '';

in

# Read a YAML file into a Nix datatype using IFD.
#
# Similar to:
#
#     builtins.fromJSON (builtins.readFile ./somefile)
#
# but takes a YAML file instead of JSON.
#
# readYAML :: Path -> a
#
# where `a` is the Nixified version of the input file.
path:
l.pipe path [
  yaml2json
  l.readFile
  l.fromJSON
]
