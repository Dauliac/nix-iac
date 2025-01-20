{ ... }:
{
  imports = [
    ../examples/minimalist-01.nix
    ../examples/minimalist-with-name-01.nix
    ../examples/minimalist-with-dependencies-01.nix
    ../examples/with-dockerhub-from-01.nix
    ../examples/with-dockerhub-from-and-tag-override-01.nix
    ../examples/with-dockerhub-from-and-name-and-tag-override-01.nix
    ../examples/minimalist-with-cve-trivy-ignore-01.nix
    ../examples/with-root-user-and-package-01.nix
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
