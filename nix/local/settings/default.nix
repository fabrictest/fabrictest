let
  inherit (inputs) std;
in
std.findTargets {
  inherit inputs cell;
  block = ./.;
}
