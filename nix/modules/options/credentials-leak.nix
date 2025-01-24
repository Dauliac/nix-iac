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
      credentialsLeak = mkOption {
        default = { };
        type = types.submodule {
          options = {
            configPath = mkOption {
              type = types.path;
              default = cfg.oci.rootPath + "/credentials-leak/";
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
