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
    mkOCIPulledManifestLockUpdateScript = mkOption {
      description = mdDoc "";
      type = types.functionTo types.package;
      default = { pkgs, self, nix2container, pulledOCI }:
          let
            manifestRootPath = cfg.lib.mkOCIPulledManifestLockRelativeRootPath {
              inherit (cfg.oci) fromImageManifestRootPath;
              inherit self;
            };
            update = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                containerName: container:
                let
                  inherit (config.oci.containers.${containerName}) fromImage;
                  manifestPath = cfg.lib.mkOCIPulledManifestLockRelativePath {
                    inherit (cfg.oci) fromImageManifestRootPath;
                    inherit fromImage;
                    inherit self;
                  };
                  manifest = cfg.lib.mkOCIPulledManifestLock {
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
    };
    mkOCIPulledManifestLockPath = mkOption {
      description = mdDoc "";
      type = types.functionTo types.path;
      default =
        {
          fromImageManifestRootPath,
          fromImage,
        }:
        let
          name = lib.strings.replaceStrings [ "/" ] [ "-" ] fromImage.imageName;
        in
        /${fromImageManifestRootPath}/${name}-${fromImage.imageTag}-manifest-lock.json;
    };
    mkOCIPulledManifestLockRelativeRootPath= mkOption {
      description = mdDoc "";
      type = types.functionTo types.str;
      default =
        rootPathConfig:
        "./"
        + lib.strings.replaceStrings [ ((toString rootPathConfig.self) + "/") ] [ "" ] (
          toString rootPathConfig.fromImageManifestRootPath
        );
    };
    mkOCIPulledManifestLockRelativePath = mkOption {
      description = mdDoc "";
      type = types.functionTo types.str;
      default =
        rootPathConfig:
        "./"
        + lib.strings.replaceStrings [ ((toString rootPathConfig.self) + "/") ] [ "" ] (
          toString (
            cfg.mkOCIPulledManifestLockPath {
              inherit (rootPathConfig)
                fromImageManifestRootPath
                fromImage
                ;
            }
          )
        );
    };
    mkOCIPulledManifestLock = mkOption {
      description = mdDoc "A function to build oci manifest to pull";
      type = types.functionTo types.package;
      default =
        {
          nix2container,
          fromImageManifestRootPath,
          fromImage,
        }:
        let
          fromImage' = fromImage // {
            imageManifest = cfg.mkOCIPulledManifestLockPath {
              inherit fromImageManifestRootPath fromImage;
            };
          };
        in
        nix2container.pullImageFromManifest fromImage';
    };
    mkOCI = mkOption {
      description = mdDoc "A function to build container";
      type = types.functionTo types.package;
      default =
        {
          pkgs,
          nix2container,
          fromImageManifestRootPath,
          package ? null,
          tag ? null,
          name ? null,
          entrypoint ? [
            "/bin/${package.name}"
            "$@"
          ],
          dependencies ? [ ],
          fromImage ? { },
          user ? package.meta.mainProgram,
        }:
        let
          name' =
            if name != null && name != "" then
              name
            else if package != null then
              lib.strings.toLower package.meta.mainProgram
            else if fromImage != { } then
              lib.strings.toLower fromImage.imageName
            else
              throw "Error: No valid source for name (name, package.meta.mainProgram, or fromImage.imageName) found.";
          tag' =
            if tag != null && tag != "" then
              # tag
              "toto"
            else if package != null then
              package.version
            else if fromImage != { } then
              fromImage.imageTag
            else
              "latest";
        in
        nix2container.buildImage {
          tag = tag';
          fromImage =
            if fromImage != { } then
              (cfg.mkOCIPulledManifestLock {
                inherit nix2container fromImageManifestRootPath fromImage;
              })
            else
              "";
          name = name';
          copyToRoot = [
            (cfg.mkRoot {
              inherit pkgs package dependencies;
            })
          ];
          config = {
            inherit entrypoint;
            Env = [
              "PATH=/bin"
              "USER=${user}"
            ];
          };
        };
    };
    mkNixOCI = mkOption {
      description = mdDoc "A function to build nix container";
      type = types.functionTo types.package;
      default =
        {
          name,
          tag,
          pkgs,
          packages,
          entrypoint,
          nix2container,
          user ? "root",
        }:
        nix2container.buildImage {
          inherit name;
          inherit tag;
          initializeNixDatabase = true;
          copyToRoot = [
            cfg.mkRoot
            {
              inherit pkgs;
              inherit packages;
            }
          ];
          layers = [
            (cfg.mkNixLayer {
              inherit user;
              inherit pkgs;
              inherit nix2container;
            })
          ];
          config = {
            inherit entrypoint;
          };
        };
    };
    mkNixOCILayer = mkOption {
      description = mdDoc "A function to build nix container";
      type = types.package;
      default =
        {
          user,
          pkgs,
          nix2container,
        }:
        nix2container.buildLayer {
          copyToRoot = [
            (pkgs.buildEnv {
              name = "root";
              paths = [
                pkgs.coreutils
                pkgs.nix
              ] ++ (config.lib.oci.mkNixShadowSetup pkgs);
              pathsToLink = [
                "/bin"
                "/etc"
              ];
            })
          ];
          config = {
            Env = [
              "NIX_PAGER=cat"
              "USER=${user}"
              "HOME=/"
            ];
          };
        };
    };
  };
}
