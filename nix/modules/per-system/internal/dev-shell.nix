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
    attrValues
    ;
in
{
  options = {
    perSystem = inputs.flake-parts.lib.mkPerSystemOption (
      {
        config,
        pkgs,
        system,
        ...
      }:
      {
        options.oci.internal = {
          packages = mkOption {
            type = types.listOf types.package;
            internal = true;
            readOnly = true;
            default = with config.oci.packages; [
             skopeo
             containerStructureTest
             podman
             grype
             syft
             trivy
             dive
            ];
          };
        };
      }
    );
  };
}
