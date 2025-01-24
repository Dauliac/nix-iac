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
    mkEnableOption
    ;
in
{
  options = {
    oci = {
      cve = mkOption {
        default = { };
        type = types.submodule {
          options = {
            # TODO: normalize name of config path dir
            configPath = mkOption {
              type = types.path;
              default = cfg.oci.rootPath + "/cve/";
              description = "";
            };
            trivy = mkOption {
              description = "Whether to try to check for CVEs using trivy.";
              default = { };
              type = types.submodule {
                options = {
                  # TODO: change all enabled into mkEnableOption
                  enabled = mkOption {
                    type = types.bool;
                    description = "";
                    default = false;
                  };
                  ignore = mkOption {
                    default = { };
                    type = types.submodule {
                      options = {
                        fileEnabled = mkOption {
                          type = types.bool;
                          description = "";
                          default = false;
                        };
                        rootPath = mkOption {
                          type = types.path;
                          description = "";
                          default = cfg.oci.cve.configPath + "/trivy/";
                        };
                        extra = mkOption {
                          type = types.listOf types.str;
                          description = "Extra CVE to ignore globally";
                          default = [ ];
                        };
                      };
                    };
                  };
                };
              };
            };
            grype = mkOption {
              description = "Whether to try to check for CVEs using grype.";
              default = { };
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    description = "";
                    default = false;
                  };
                  config = mkOption {
                    default = { };
                    type = types.submodule {
                      options = {
                        enabled = mkEnableOption "";
                        rootPath = mkOption {
                          type = types.path;
                          description = "";
                          default = cfg.oci.cve.configPath + "/grype/";
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
        description = "Whether to check for CVEs.";
      };
    };
  };
}
