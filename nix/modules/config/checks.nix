localflake:
{
  config,
  lib,
  ...
}:
let
  localLib = localflake.config.lib;
  cfg = config;
  inherit (lib)
    mkIf
    mkMerge
    attrsets
    ;
in
{
  config = mkIf (config.oci != null && config.oci.enabled) {
    perSystem =
      {
        config,
        pkgs,
        inputs',
        system,
        ...
      }:
      let
        oci = attrsets.mapAttrs (
          containerName: containerConfig:
          localLib.mkOCI {
            inherit pkgs;
            inherit containerName;
            config = cfg.oci;
            perSystemConfig = config.oci;
          }
        ) config.oci.containers;
        ociDive = localLib.filterEnabledOutputsSet {
          config = config.oci.containers;
          subConfig = "dive";
        };
        diveChecks = lib.genAttrs (lib.attrNames ociDive) (
          containerName:
          localLib.mkCheckDive {
            inherit pkgs;
            inherit (config.oci.packages) skopeo dive;
            oci = oci.${containerName};
          }
        );
        prefixedDiveChecks = localLib.prefixOutputs {
          prefix = "oci-dive-";
          set = diveChecks;
        };
      in
      {
        checks = mkIf cfg.oci.enableCheck (mkMerge [
          prefixedDiveChecks
        ]);
      };
  };
}
