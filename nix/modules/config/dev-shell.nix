localflake:
{
  config,
  lib,
  ...
}:
let
  cfg = config;
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
        devShells.default = mkIf cfg.oci.enableDevShell (
          pkgs.mkShell {
            # BUG: fix puller
            # shellHook = ''
            #   ${config.packages.oci-updatePulledManifestsLocks}/bin/update-pulled-oci-manifests-locks
            # '';
          }
        );
      };
  };
}
