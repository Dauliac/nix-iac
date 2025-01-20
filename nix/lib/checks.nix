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
in
{
  options.lib = {
    mkCheckDive = mkOption {
      description = mdDoc "A function to create a check that runs dive on a built image";
      type = types.functionTo types.package;
      default =
        {
          oci,
          pkgs,
          dive,
          skopeo,
        }:
        let
          archive = config.lib.mkDockerArchive { inherit oci pkgs skopeo; };
        in
        pkgs.runCommandLocal "dive-check"
          {
            buildInputs = [
              dive
            ];
            meta.description = "Run dive on built image.";
          }
          ''
            set -e
            dive --ci --json $out docker-archive://${archive}
          '';
    };
  };
}
