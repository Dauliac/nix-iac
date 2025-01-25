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
    types
    ;
in
{
  options.lib = {
    mkAppCVETrivy = mkOption {
      description = mdDoc "To build trivy app to check for CVEs on OCI.";
      type = types.functionTo types.attrs;
      default =
        args@{
          config,
          perSystemConfig,
          containerId,
          oci,
          pkgs,
        }:
        let
          containerConfig = args.perSystemConfig.containers.${containerId}.cve.trivy;
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
          program = args.pkgs.writeShellScriptBin "trivy" ''
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
    mkAppCVEGrype = mkOption {
      description = mdDoc "To build grype app to check for CVEs on OCI.";
      type = types.functionTo types.attrs;
      default =
        args@{
          config,
          perSystemConfig,
          containerId,
          oci,
          pkgs,
        }:
        let
          containerConfig = args.perSystemConfig.containers.${containerId}.cve.grype;
          archive = cfg.lib.mkDockerArchive {
            inherit (args) oci pkgs;
            inherit (perSystemConfig) skopeo;
          };
          configFlag =
            if containerConfig.config.enabled then "--config ${containerConfig.config.path}" else "";
        in
        {
          type = "app";
          program = args.pkgs.writeShellScriptBin "grype" ''
            set -o errexit
            set -o pipefail
            set -o nounset
            ${args.perSystemConfig.packages.grype}/bin/grype \
              ${configFlag} \
              ${archive}
          '';
        };
    };
  };
}
