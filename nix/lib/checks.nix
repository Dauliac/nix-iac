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
    mkDockerArchive = mkOption {
      description = mdDoc "";
      type = types.functionTo types.package;
      default =
        {
          oci,
          skopeo,
          pkgs,
        }:
        pkgs.runCommandLocal "docker-archive"
          {
            buildInputs = [
              skopeo
            ];
            meta.description = "Run dive on built image.";
          }
          ''
            set -e
            skopeo --tmpdir $TMP --insecure-policy copy nix:${oci} docker-archive:archive.tar
            mv archive.tar $out
          '';
    };
    mkCheckDive = mkOption {
      description = mdDoc "";
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
