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
      # TODO: move it into test submodule
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
    };
  };
}
