{ lib, terranix, ... }@pkgs:
with lib;
rec {

  terraformRemoteStates = mapToAttrs (name: {
    name = replaceString "/" "_" name;
    value = terraformRemoteState name;
  });

  terraformRemoteState =
    name:
    terraformRemoteStateWith {
      modules = [ ../infrastructure/${name}/config.nix ];
    };

  terraformRemoteStateWith =
    { modules }:
    {
      backend = "http";
      config = (terranixConfigWith { inherit modules; }).config.terraform.backend.http;
    };

  terranixConfigWith =
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
