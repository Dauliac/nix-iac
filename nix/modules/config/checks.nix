localflake:
{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    ;
in
{
  config = mkIf config.oci.enabled {
    perSystem =
      {
        config,
        pkgs,
        inputs',
        system,
        ...
      }:
      {
        checks = mkMerge [
          config.oci.internal.prefixedDiveChecks
        ];
      };
  };
}
