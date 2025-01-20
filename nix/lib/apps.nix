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
          oci,
          pkgs,
          trivy,
          skopeo,
        }:
        let
          archive = cfg.lib.mkDockerArchive { inherit (args) oci pkgs skopeo; };
          ignoreFileFlag =
            if args.config.trivy.ignore.enabled then "--ignorefile ${args.config.trivy.ignore.path}" else "";
        in
        {
          type = "app";
          program = args.pkgs.writeShellScriptBin "update-pulled-oci-manifests-locks" ''
            set -o errexit
            set -o pipefail
            set -o nounset
            ${args.trivy}/bin/trivy image --input ${archive} ${ignoreFileFlag}
          '';
        };
    };
  };
}
