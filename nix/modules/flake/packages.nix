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
        packages = lib.mkMerge [
          {
            # BUG: fix puller
            # oci-updatePulledManifestsLocks = updatepulledOCIsManifestLocks;
            oci-all = config.oci.internal.allOCIs;
          }
          config.oci.internal.prefixedOCIs
        ];
      };
  };
}
