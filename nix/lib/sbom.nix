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
    mkAppSBOMSyft = mkOption {
      description = mdDoc "To build syft app to check for CVEs on OCI.";
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
          containerConfig = args.perSystemConfig.containers.${ContainerId}.sbom.syft;
          archive = cfg.lib.mkDockerArchive {
            inherit (args) oci pkgs;
            inherit (perSystemConfig) skopeo;
          };
          configFlag =
            if containerConfig.config.enabled then "--config ${containerConfig.config.path}" else "";
        in
        {
          type = "app";
          program = args.pkgs.writeShellScriptBin "syft" ''
            set -o errexit
            set -o pipefail
            set -o nounset
            ${args.perSystemConfig.packages.syft}/bin/syft \
              ${configFlag} \
              ${archive}
          '';
        };
    };
  };
}
