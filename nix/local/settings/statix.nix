# https://git.peppe.rs/languages/statix/about/
let
  inherit (inputs) std;
  inherit (cell) pkgs;
in
std.lib.dev.mkNixago {

  output = "statix.toml";

  packages = [
    pkgs.statix
  ];

  data = {
    disabled = [ ];
    ignore = [ ".direnv" ];
  };
}
