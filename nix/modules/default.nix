localflake:
{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  cfg = config;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    attrsets
    foldl'
    ;
in
{
  options = {
    oci = {
      enabled = mkEnableOption "Enable the OCI module.";
      devShellPackage = mkOption {
        type = types.package;
        description = "The package to use for the dev shell.";
      };
      enableDevShell = mkOption {
        type = types.bool;
        description = "Enable the dev shell.";
        default = true;
      };
      fromImageManifestRootPath = mkOption {
        type = types.path;
        default = ./.oci;
        description = "The root path to store the pulled oci image manifest json lockfiles.";
      };
      registry = mkOption {
        type = types.str;
        default = "";
        description = "The OCI registry to use for pushing and pulling images.";
      };
    };
    perSystem = inputs.flake-parts.lib.mkPerSystemOption (
      {
        config,
        pkgs,
        ...
      }:
      {
        options.oci.containers = mkOption {
          type = types.attrsOf (
            types.submodule (
              { name, ... }:
              {
                options = {
                  tag = mkOption {
                    type = types.nullOr types.str;
                    description = "Tag of the container.";
                  };
                  package = mkOption {
                    type = types.nullOr types.package;
                    description = "The main package for the container";
                    default = null;
                  };
                  name = mkOption {
                    type = types.nullOr types.str;
                    description = "Name of the container.";
                    default = null;
                  };
                  fromImage = mkOption {
                    description = "The image to use as the base image.";
                    type = types.attrsOf types.str;
                    default = { };
                    example = {
                      imageName = "library/alpine";
                      imageTag = "latest";
                      os = "linux";
                      arch = "amd64";
                    };
                  };
                  dependencies = mkOption {
                    type = types.listOf types.package;
                    description = "Additional dependencies packages to include in the container.";
                    default = [ ];
                  };
                  isRoot = mkOption {
                    type = types.bool;
                    description = "Whether the container is a root container.";
                    default = false;
                  };
                  installNix = mkOption {
                    type = types.bool;
                    description = "Whether to install nix in the container.";
                    default = false;
                  };
                  push = mkOption {
                    type = types.bool;
                    description = "Whether to push the container to the OCI registry.";
                    default = false;
                  };
                };
              }
            )
          );
          description = "Definitions for all containers.";
          default = { };
          example = {
            package = pkgs.hello;
            dependencies = [ pkgs.bash ];
          };
        };
      }
    );
  };
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
        nix2container = localflake.inputs.nix2container.packages.${system}.nix2container;
        pulledOCI =
          attrsets.mapAttrs
            (
              containerName: containerConfig:
              if containerConfig.fromImage != { } then
                localflake.inputs.nix2container.packages.${system}.nix2container.pullImageFromManifest
                  containerConfig.fromImage
                // {
                  imageManifest = cfg.lib.mkManifestPath {
                    inherit (cfg.oci) fromImageManifestRootPath;
                    inherit (containerConfig) fromImage;
                  };
                }
              else
                null
            )
            (attrsets.filterAttrs (_: containerConfig: containerConfig.fromImage != { }) config.oci.containers);
        oci = attrsets.mapAttrs (
          containerName: containerConfig:
          localflake.config.lib.mkOCI {
            inherit (cfg.oci) fromImageManifestRootPath;
            inherit pkgs;
            inherit (containerConfig)
              package
              tag
              name
              dependencies
              fromImage
              ;
            inherit nix2container;
          }
        ) config.oci.containers;
        prefixedOCI = foldl' (
          acc: containerName:
          acc
          // {
            "oci-${containerName}" = oci.${containerName};
          }
        ) { } (attrsets.attrNames oci);
        updatePulledOCIManifestLocks =
          let
            manifestRootPath = localflake.config.lib.mkRelativeManifestRootPath {
              inherit (cfg.oci) fromImageManifestRootPath;
              inherit self;
            };
            update = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                containerName: container:
                let
                  inherit (config.oci.containers.${containerName}) fromImage;
                  manifestPath = localflake.config.lib.mkRelativeManifestPath {
                    inherit (cfg.oci) fromImageManifestRootPath;
                    inherit fromImage;
                    inherit self;
                  };
                  manifest = localflake.config.lib.mkManifest {
                    inherit nix2container;
                    inherit (cfg.oci) fromImageManifestRootPath;
                    inherit fromImage;
                  };
                in
                ''
                  declare -g manifest
                  manifest=$(${manifest.getManifest}/bin/get-manifest)
                  if [ -f "${manifestPath}" ]; then
                    currentContent=$(cat "${manifestPath}")
                    newContent=$(echo "$manifest")
                    if [ "$currentContent" != "$newContent" ]; then
                      printf "Updating lock manifest for ${containerName}::${fromImage.imageName}:${fromImage.imageTag} ...\n"
                      echo "$manifest" > "${manifestPath}"
                    fi
                  else
                    printf "Generating lock manifest for ${containerName}::${fromImage.imageName}:${fromImage.imageTag} ...\n"
                    echo "$manifest" > "${manifestPath}"
                  fi
                ''
              ) pulledOCI
            );
          in
          pkgs.writeShellScriptBin "update-pulled-oci-manifests-locks" ''
            set -o errexit
            set -o pipefail
            set -o nounset

            mkdir -p "${manifestRootPath}"
            ${update}
          '';
      in
      {
        apps = {
          oci-updatePulledManifestLocks = {
            type = "app";
            program = updatePulledOCIManifestLocks;
          };
        };
        packages = lib.mkMerge [
          {
            oci-updatePulledManifestLocks = updatePulledOCIManifestLocks;
          }
          prefixedOCI
        ];
        devShells.default = mkIf cfg.oci.enableDevShell (
          pkgs.mkShell {
            shellHook = ''
              ${config.packages.oci-updatePulledManifestLocks}/bin/update-pulled-oci-manifests-locks

            '';
          }
        );
      };
  };
}
