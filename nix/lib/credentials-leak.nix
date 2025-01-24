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
    mkAppCredentialsLeakTrivy = mkOption {
      description = mdDoc "To build trivy app to check for CVEs on OCI.";
      type = types.functionTo types.attrs;
      default =
        args@{
          config,
          perSystemConfig,
          ContainerId,
          oci,
          pkgs,
        }:
        let
          archive = cfg.mkDockerArchive {
            inherit (args) oci pkgs;
            inherit (perSystemConfig) skopeo;
          };
        in
        {
          type = "app";
          program = args.pkgs.writeShellScriptBin "trivy" ''
            set -o errexit
            set -o pipefail
            set -o nounset
            set -x
            ${args.perSystemConfig.packages.trivy}/bin/trivy image \
              --input ${archive} \
              --exit-code 1 \
              --scanners secret
          '';
        };
    };
  };
}
