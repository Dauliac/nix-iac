localflake:
{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  cfg = config;
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    oci = {
      sbom = mkOption {
        default = { };
        description = "Whether to generate SBOMs.";
        type = types.submodule {
          options = {
            path = mkOption {
              type = types.path;
              description = "";
              default = cfg.oci.rootPath + "sbom/";
            };
            # TODO include slim sbom
            syft = mkOption {
              default = { };
              description = "";
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    description = "";
                    default = false;
                  };
                  config = mkOption {
                    description = "";
                    default = { };
                    type = types.submodule {
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          description = "";
                          default = false;
                        };
                        rootPath = mkOption {
                          type = types.path;
                          description = "";
                          default = cfg.oci.sbom.rootPath + "/syft";
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
