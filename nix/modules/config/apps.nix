localflake:
{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  localLib = localflake.config.lib;
  cfg = config;
  inherit (lib)
    mkIf
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
        pulledOCI =
          attrsets.mapAttrs
            (
              containerName: containerConfig:
              if containerConfig.fromImage != { } then
                config.oci.packages.pullImageFromManifest containerConfig.fromImage
                // {
                  imageManifest = cfg.lib.mkOCIPulledManifestLockPath {
                    inherit (config.oci.packages) nix2containers;
                    inherit (cfg.oci) fromImageManifestRootPath;
                    inherit (containerConfig) fromImage;
                  };
                }
              else
                null
            )
            (
              attrsets.filterAttrs (_: containerConfig: containerConfig.fromImage != null) config.oci.containers
            );
        oci = attrsets.mapAttrs (
          containerName: containerConfig:
          localLib.mkOCI {
            inherit pkgs;
            inherit containerName;
            config = cfg.oci;
            perSystemConfig = config.oci;
          }
        ) config.oci.containers;
        updatePulledOCIManifestLocks = localLib.mkOCIPulledManifestLockUpdateScript {
          inherit
            pkgs
            self
            pulledOCI
            ;
          inherit (config.oci) containers;
          inherit (cfg.oci) fromImageManifestRootPath;
          perSystemConfig = config.oci;
        };
        ociCVETrivy = localLib.filterEnabledOutputsSet {
          config = config.oci.containers;
          subConfig = "cve.trivy";
        };
        cveTrivy = lib.genAttrs (lib.attrNames ociCVETrivy) (
          containerName:
          localLib.mkAppCVETrivy {
            inherit pkgs containerName;
            config = cfg.oci;
            perSystemConfig = config.oci;
            oci = oci.${containerName};
          }
        );
        prefixedCveTrivy = localLib.prefixOutputs {
          prefix = "oci-cve-trivy-";
          set = cveTrivy;
        };
        ociGrype = localLib.filterEnabledOutputsSet {
          config = config.oci.containers;
          subConfig = "cve.grype";
        };
        cveGrype = lib.genAttrs (lib.attrNames ociGrype) (
          containerName:
          localLib.mkAppCVEGrype {
            inherit pkgs containerName;
            config = cfg.oci;
            perSystemConfig = config.oci;
            oci = oci.${containerName};
          }
        );
        prefixedCveGrype = localLib.prefixOutputs {
          prefix = "oci-cve-grype-";
          set = cveGrype;
        };
        ociCredentialsLeakTrivy = localLib.filterEnabledOutputsSet {
          config = config.oci.containers;
          subConfig = "credentialsLeak.trivy";
        };
        credentialsLeakTrivy = lib.genAttrs (lib.attrNames ociCredentialsLeakTrivy) (
          containerName:
          localLib.mkAppCredentialsLeakTrivy {
            inherit pkgs containerName;
            config = cfg.oci;
            perSystemConfig = config.oci;
            oci = oci.${containerName};
          }
        );
        prefixedCredentialsLeakTrivy = localLib.prefixOutputs {
          prefix = "oci-creds-leak-trivy-";
          set = credentialsLeakTrivy;
        };
        ociSBOMSyft = localLib.filterEnabledOutputsSet {
          config = config.oci.containers;
          subConfig = "sbom.syft";
        };
        sbomSyft = lib.genAttrs (lib.attrNames ociSBOMSyft) (
          containerName:
          localLib.mkAppSBOMSyft {
            inherit pkgs containerName;
            config = cfg.oci;
            perSystemConfig = config.oci;
            oci = oci.${containerName};
          }
        );
        prefixedSBOMSyft = localLib.prefixOutputs {
          prefix = "oci-sbom-syft-";
          set = sbomSyft;
        };
        ociContainerStructureTests = localLib.filterEnabledOutputsSet {
          config = config.oci.containers;
          subConfig = "containerStructureTest";
        };
        containerStructureTestsApps =
          lib.genAttrs (lib.attrNames ociContainerStructureTests)
            (containerId: {
              type = "app";
              program = localLib.mkScriptContainerStructureTest {
                inherit pkgs containerId;
                perSystemConfig = config.oci;
                oci = oci.${containerId};
                config = config.oci;
              };
            });
        prefixedContainerStructureTests = localLib.prefixOutputs {
          prefix = "oci-container-structure-test-";
          set = containerStructureTestsApps;
        };
      in
      {
        apps = lib.mkMerge [
          {
            # BUG: fix puller
            # oci-updatePulledManifestsLocks = {
            #   type = "app";
            #   program = updatePulledOCIManifestLocks;
            # };
          }
          prefixedContainerStructureTests
          prefixedCveGrype
          prefixedCveTrivy
          prefixedCredentialsLeakTrivy # TODO: check if this script can be a check
          prefixedSBOMSyft
        ];
      };
  };
}
