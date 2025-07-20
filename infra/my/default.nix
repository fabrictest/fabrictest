{ lib, terranix, ... }@pkgs:
rec {

  tfRemoteStates = mapToAttrs (name: {
    name = lib.replaceString "/" "_" name;
    value = tfRemoteState name;
  });

  tfRemoteState =
    name:
    tfRemoteStateWith {
      modules = [ ../${name}/config.nix ];
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
      terranix_config.imports = modules;
    };

  mapToAttrs = f: l: lib.listToAttrs (lib.map f l);
}
