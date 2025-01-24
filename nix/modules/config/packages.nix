localflake:
{
  config,
  lib,
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
        prefixedOCI = localLib.prefixOutputs {
          prefix = "oci-";
          set = oci;
        };
        allOCI =
          pkgs.runCommand "oci-all"
            {
              buildInputs = [ ];
            }
            ''
              mkdir -p $out
              ${lib.concatMapStringsSep "\n" (
                name:
                let
                  package = prefixedOCI.${name};
                in
                ''
                  echo "Building container: ${name}"
                  cp ${package} $out/${name}
                ''
              ) (attrsets.attrNames prefixedOCI)}
            '';
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
      in
      {
        packages = lib.mkMerge [
          {
            # BUG: fix puller
            # oci-updatePulledManifestsLocks = updatePulledOCIManifestLocks;
            oci-all = allOCI;
          }
          prefixedOCI
        ];
      };
  };
}
