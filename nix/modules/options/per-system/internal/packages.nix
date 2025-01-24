localflake:
{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  localLib = localflake.config.lib;
  cfg = config;
  inherit (lib)
    mkOption
    types
    attrsets
    ;
in
{
  options = {
    perSystem = inputs.flake-parts.lib.mkPerSystemOption (
      {
        config,
        pkgs,
        system,
        ...
      }:
      {
        options.oci.internal = {
          pulledOCI = mkOption {
            type = types.attrsOf types.package;
            internal = true;
            readOnly = true;
            default =
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
          };
          OCIs = mkOption {
            type = types.attrsOf types.package;
            default = attrsets.mapAttrs (
              containerName: containerConfig:
              localLib.mkOCI {
                inherit pkgs;
                inherit containerName;
                config = cfg.oci;
                perSystemConfig = config.oci;
              }
            ) config.oci.containers;
          };
          prefixedOCIs = mkOption {
            type = types.attrsOf types.package;
            internal = true;
            readOnly = true;
            default = localLib.prefixOutputs {
              prefix = "oci-";
              set = config.oci.internal.OCIs;
            };
          };
          allOCIs = mkOption {
            type = types.package;
            internal = true;
            readOnly = true;
            default =
              pkgs.runCommand "oci-all"
                {
                  buildInputs = [ ];
                }
                ''
                  mkdir -p $out
                  ${lib.concatMapStringsSep "\n" (
                    name:
                    let
                      package = config.oci.internal.prefixedOCIs.${name};
                    in
                    ''
                      echo "Building container: ${name}"
                      cp ${package} $out/${name}
                    ''
                  ) (attrsets.attrNames config.oci.internal.prefixedOCIs)}
                '';
          };
          updatePulledOCIManifestLocks = mkOption {
            type = types.package;
            internal = true;
            readOnly = true;
            default = localLib.mkOCIPulledManifestLockUpdateScript {
              inherit
                pkgs
                self
                ;
              inherit (config.oci.internal) pulledOCI;
              inherit (config.oci) containers;
              inherit (cfg.oci) fromImageManifestRootPath;
              perSystemConfig = config.oci;
            };
          };
        };
      }
    );
  };
}
