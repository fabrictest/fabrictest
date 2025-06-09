{ pkgs }:
rec {

  tfConfig = path: tfConfigWith { modules = [ path ]; };

  tfConfigWith =
    {
      modules,
    }:
    import (pkgs.terranix + /core) {
      inherit pkgs;
      terranix_config.imports = modules;
    };

  tfRemoteState = path: tfRemoteStateWith { modules = [ path ]; };

  tfRemoteStateWith =
    {
      modules,
    }:
    rec {
      backend = "http";
      config = (tfConfigWith { inherit modules; }).config.terraform.backend.${backend};
    };

}
