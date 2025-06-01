{ pkgs }:
rec {

  terraformConfiguration =
    {
      modules ? [ ],
    }:
    import (pkgs.terranix + /core) {
      inherit pkgs;
      terranix_config.imports = modules;
    };

  terraformRemoteState =
    {
      modules ? [ ],
    }:
    let
      backend = "http";
      inherit
        (terraformConfiguration {
          inherit modules;
        })
        config
        ;
    in
    {
      inherit backend;
      config = config.terraform.backend.${backend};
    };

}
