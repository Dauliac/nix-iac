{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkOption
    mdDoc
    types
    ;
  cfg = config.lib;
in
{
  options.lib = {
    mkScriptContainerStructureTest = mkOption {
      description = mdDoc "A function to create a check that runs container-structure-test on a built image using podman.";
      type = types.functionTo types.package;
      default =
        {
          pkgs,
          perSystemConfig,
          containerId,
        }:
        let
          policy = cfg.mkPodmanPolicy pkgs;
          oci = perSystemConfig.internal.OCIs.${containerId};
          configFlags = lib.concatStringsSep " " (
            lib.map (
              config: "--config=${config}"
            ) perSystemConfig.containers.${containerId}.test.containerStructureTest.configs
          );

          # TODO: add option to configure tests output format
          cst = pkgs.writeShellScriptBin "container-structure-test" ''
            ${oci.copyToPodman}/bin/copy-to-podman
            set -x
            ${perSystemConfig.packages.containerStructureTest}/bin/container-structure-test \
              test --image "${oci.imageName}:${oci.imageTag}" \
              --runtime podman \
              --output text \
              "${configFlags}"
          '';
          envRunScript = pkgs.writeScriptBin "run" ''
            set -o errexit
            set -o nounset
            set -o pipefail

            main() {
              ${./run-oci-podman.sh} "${cst}/bin/container-structure-test"
            }

            main "$@"
          '';
          fhsEnv = pkgs.buildFHSEnv {
            name = "container-structure-test";
            extraBuildCommands = ''
              cp -r ${policy}/* $out/
            '';
            runScript = "${envRunScript}/bin/run";
          };
        in
        pkgs.writeScriptBin "container-structure-test" ''
          export PATH="${pkgs.podman}/bin:${pkgs.bash}/bin"
          ${fhsEnv}/bin/container-structure-test
        '';
    };
    mkAppContainerStructureTest = mkOption {
      description = mdDoc "A function to create a check that runs container-structure-test on a built image using podman.";
      type = types.functionTo types.attrs;
      default = args: {
        type = "app";
        program = cfg.mkScriptContainerStructureTest args;
      };
    };
  };
}
