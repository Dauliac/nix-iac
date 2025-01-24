{ ... }:
{
  config = {
    perSystem =
      {
        pkgs,
        config,
        ...
      }:
      {
        checks = {
          # buildScripts = pkgs.runCommand "build-scripts" {
          #   buildInputs = [ config.packages.oci-updatePulledManifestsLocks ];
          # } "touch $out";
        };
      };
  };
}
