{ lib, terranix, ... }@pkgs:
with lib;
rec {

  tfRemoteStates = mapToAttrs (name: {
    name = replaceString "/" "_" name;
    value = tfRemoteState name;
  });

  tfRemoteState =
    name:
    tfRemoteStateWith {
      modules = [ ../infrastructure/${name}/config.nix ];
    };

  tfRemoteStateWith =
    { modules }:
    rec {
      backend = "http";
      config = (tfConfigWith { inherit modules; }).config.terraform.backend.${backend};
    };

  tfConfigWith =
    { modules }:
    import (terranix + /core) {
      inherit pkgs;
      terranix_config = {
        imports = modules;
      };
    };

  mapToAttrs = f: l: listToAttrs (map f l);

  mapCartesianProductToAttrs = f: l: listToAttrs (mapCartesianProduct f l);
}
