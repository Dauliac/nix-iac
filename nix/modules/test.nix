localflake:
{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;
in
{
  options = {
    oci = {
      test = mkOption {
        default = { };
        type = types.submodule {
          options = {
            dive = mkOption {
              default = { };
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    description = "";
                    default = false;
                  };
                };
              };
            };
            containerStructureTest = mkOption {
              default = { };
              type = types.submodule {
                options = {
                  enabled = mkOption {
                    type = types.bool;
                    description = "";
                    default = false;
                  };
                };
              };
            };
            dgoss = mkOption {
              default = { };
              type = types.submodule {
                options = {
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
      };
    };
  };
}
