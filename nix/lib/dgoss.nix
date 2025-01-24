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
    mkScriptDgoss = mkOption {
      description = mdDoc "A function to create a check that runs dgoss on a built image using podman.";
      type = types.functionTo types.package;
      default =
        {
          pkgs,
          oci,
          dgoss,
          perSystemConfig,
          containerId,
          config,
        }:
        let
          name = "dgoss";
          policy = cfg.mkPodmanPolicy pkgs;
          dgoss = pkgs.writeShellScriptBin name ''
            set -o errexit
            set -o nounset
            set -o pipefail
            ${oci.copyToPodman}/bin/copy-to-podman
            GOSS_FILE=${config.containers.${containerId}.dgoss.config}
            GOSS_FILES_STRATEGY=cp
            CONTAINER_RUNTIME=podman
            ${perSystemConfig.packages.${name}}/bin/${name} \
              run "${oci.imageName}:${oci.imageTag}"
          '';
          fhsEnv = pkgs.buildFHSEnv {
            inherit name;
            extraBuildCommands = ''
              cp -r ${policy}/* $out/
            '';
            runScript = "${dgoss}/bin/run";
          };
        in
        pkgs.writeScriptBin name ''
          export PATH="${pkgs.podman}/bin:${pkgs.bash}/bin"
          ${fhsEnv}/bin/${name}
        '';
    };
  };
}
