{ ... }:
{
  imports = [
    ./minimalist-01.nix
    ./minimalist-with-name-01.nix
    ./minimalist-with-dependencies-01.nix
    ./with-dockerhub-from-01.nix
    ./with-dockerhub-from-and-tag-override-01.nix
    ./with-dockerhub-from-and-name-and-tag-override-01.nix
    ./with-root-user-and-package-01.nix
  ];
  config = {
    perSystem =
      {
        pkgs,
        config,
        ...
      }:
      {
        checks = {
          buildExamples = pkgs.runCommand "build-examples" {
            buildInputs = [ config.packages.oci-all ];
          } "touch $out";
          buildScripts = pkgs.runCommand "build-scripts" {
            buildInputs = [ config.packages.oci-updatePulledManifestsLocks ];
          } "touch $out";
        };
      };
  };
}
