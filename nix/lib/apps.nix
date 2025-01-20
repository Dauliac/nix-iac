{
  lib,
  config,
  ...
}:
let
  cfg = config;
  inherit (lib)
    mkOption
    mdDoc
    # types
    ;
in
{
  options.lib = {
    mkAppCVETrivy = mkOption {
      description = mdDoc "To build trivy app to check for CVEs on OCI.";
      # type = types.function;
      default =
        args@{
          config,
          perSystemConfig,
          containerName,
          oci,
          pkgs,
        }:
        let
          containerConfig = args.perSystemConfig.containers.${containerName}.cve.trivy;
          archive = cfg.lib.mkDockerArchive {
            inherit (args) oci pkgs;
            inherit (perSystemConfig) skopeo;
          };
          ignoreFileFlag =
            if containerConfig.ignore.fileEnabled then "--ignorefile ${containerConfig.ignore.path}" else "";
          extraIgnoreFile = pkgs.writeText "extra-ignore.ignore" ''
            ${lib.concatMapStrings (ignore: "${ignore}\n") args.config.trivy.ignore.extra}
          '';
          extraIgnoreFileFlag =
            if (lib.length config.cve.trivy.ignore.extra) > 0 then "--ignorefile ${extraIgnoreFile}" else "";
          containerExtraIgnoreFile = pkgs.writeText "container-extra-ignore.ignore" ''
            ${lib.concatMapStrings (ignore: "${ignore}\n") containerConfig.ignore.extra}
          '';
          containerExtraIgnoreFileFlag =
            if (lib.length containerConfig.ignore.extra) > 0 then
              "--ignorefile ${containerExtraIgnoreFile}"
            else
              "";
        in
        {
          type = "app";
          program = args.pkgs.writeShellScriptBin "update-pulled-oci-manifests-locks" ''
            set -o errexit
            set -o pipefail
            set -o nounset
            ${args.perSystemConfig.trivy}/bin/trivy image \
              --input ${archive} ${ignoreFileFlag} ${extraIgnoreFileFlag} ${containerExtraIgnoreFileFlag} \
              --exit-code 1 \
              --scanners vuln
          '';
        };
    };
  };
}
