{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkOption
    mdDoc
    mkIf
    types
    ;
  cfg = config.lib;
in
{
  options.lib = {
    mkOCIPulledManifestLockUpdateScript = mkOption {
      description = mdDoc "A function to build script to update pulled OCI manifests locks";
      type = types.functionTo types.package;
      default =
        {
          pkgs,
          self,
          nix2container,
          containers,
          pulledOCI,
          fromImageManifestRootPath,
        }:
        let
          manifestRootPath = cfg.mkOCIPulledManifestLockRelativeRootPath {
            inherit fromImageManifestRootPath;
            inherit self;
          };
          update = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              containerName: container:
              let
                inherit (containers.${containerName}) fromImage;
                manifestPath = cfg.mkOCIPulledManifestLockRelativePath {
                  inherit fromImageManifestRootPath;
                  inherit fromImage;
                  inherit self;
                };
                manifest = cfg.mkOCIPulledManifestLock {
                  inherit nix2container;
                  inherit fromImageManifestRootPath;
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
      description = mdDoc "A function to build OCI manifest to pull";
      type = types.functionTo types.path;
      default =
        {
          fromImageManifestRootPath,
          fromImage,
        }:
        let
          name = lib.strings.replaceStrings [ "/" ] [ "-" ] fromImage.imageName;
        in
        fromImageManifestRootPath + name + "-" + fromImage.imageTag + "-manifest-lock.json";
    };
    mkOCIPulledManifestLockRelativeRootPath = mkOption {
      description = mdDoc "A function to get relative path lock manifest of to pull OCI";
      type = types.functionTo types.str;
      default =
        args:
        "./"
        + lib.strings.replaceStrings [ ((toString args.self) + "/") ] [ "" ] (
          toString args.fromImageManifestRootPath
        );
    };
    mkOCIPulledManifestLockRelativePath = mkOption {
      description = mdDoc "Generate local relive path to download OCI";
      type = types.functionTo types.str;
      default =
        args:
        "./"
        + lib.strings.replaceStrings [ ((toString args.self) + "/") ] [ "" ] (
          toString (
            cfg.mkOCIPulledManifestLockPath {
              inherit (args)
                fromImageManifestRootPath
                fromImage
                ;
            }
          )
        );
    };
    mkOCIPulledManifestLock = mkOption {
      description = mdDoc "A function to build OCI manifest to pull";
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
          manifest = nix2container.pullImageFromManifest fromImage';
        in
        manifest;
    };
    mkOCIName = mkOption {
      type = types.functionTo types.str;
      description = mdDoc "A function to get name of container";
      default =
        {
          package,
          fromImage,
        }:
        if package != null then
          lib.strings.toLower package.meta.mainProgram
        else if fromImage != { } then
          lib.strings.toLower fromImage.imageName
        else
          throw "Error: No valid source for name (name, package.meta.mainProgram, or fromImage.imageName) found.";
    };
    mkOCIUser = mkOption {
      type = types.functionTo types.str;
      description = mdDoc "A function to get user of container";
      default =
        {
          isRoot,
          name,
        }:
        let
          user' =
          if isRoot then
            "root"
          else if name != null && name != "" then
            name
          else
            throw "No user given and impossible to infer it from name or isRoot";
        in
          user';

    };
    mkOCITag = mkOption {
      type = types.functionTo types.str;
      description = mdDoc "A function to get tag of container";
      default =
      { package, fromImage }:
      let
        tag' =
        if package != null && package.version != null then
          package.version
        else if fromImage != null && fromImage.imageTag != null then
          fromImage.imageTag
        else
          throw "Empty tag given and impossible to infer it from package or fromImage";
      in
        tag';

    };
    mkOCIEntrypoint = mkOption {
      type = types.functionTo (types.listOf types.str);
      description = mdDoc "A function to get entrypoint of container";
      default =
        {
          entrypoint,
          package,
        }:
        let
          entrypoint' = if entrypoint != [ ] then
            entrypoint
            else if package != null then
              [
                "/bin/${package.meta.mainProgram}"
             ]
            else
              [ ];
        in
        entrypoint';
    };
    mkOCI = mkOption {
      description = mdDoc "A function to build container";
      type = types.functionTo types.package;
      default =
        args@{
          pkgs,
          nix2container,
          fromImageManifestRootPath,
          package,
          isRoot,
          installNix,
          user,
          tag,
          name,
          entrypoint,
          dependencies,
          fromImage,
        }:
        if args.installNix then cfg.mkNixOCI args else cfg.mkSimpleOCI args;
    };
    mkSimpleOCI = mkOption {
      description = mdDoc "A function to build simple container";
      type = types.functionTo types.package;
      default =
        args:
        (args.nix2container.buildImage {
          inherit (args) tag name;
          # NOTE: here we can't use mkIf because fromImage with empty value require an empty string

          fromImage = if  args.fromImage == null then
              ""
            else
              cfg.mkOCIPulledManifestLock {
                inherit (args) nix2container fromImageManifestRootPath fromImage;
              };
          copyToRoot = [
            (cfg.mkRoot {
              inherit (args)
                pkgs
                package
                dependencies
                tag
                ;
            })
          ];
          config = {
            inherit (args) entrypoint;
            Env = [
              "PATH=/bin"
              "USER=${args.user}"
            ];
          };
        });
    };
    mkNixOCI = mkOption {
      description = mdDoc "A function to build nix container";
      type = types.functionTo types.package;
      default =
        args:
        args.nix2container.buildImage {
          inherit (args) name tag;
          initializeNixDatabase = true;
          copyToRoot = [
            cfg.mkRoot
            {
              inherit (args) pkgs package tag;
            }
          ];
          layers = [
            (cfg.mkNixOCILayer {
              inherit (args) user pkgs nix2container;
            })
          ];
          config = {
            inherit (args) entrypoint;
          };
        };
    };
    mkNixOCILayer = mkOption {
      description = mdDoc "A function to build nix container";
      type = types.package;
      default =
        args:
        args.nix2container.buildLayer {
          copyToRoot = [
            (args.pkgs.buildEnv {
              name = "root";
              paths =
                with args.pkgs;
                [
                  coreutils
                  nix
                ]
                ++ (config.lib.oci.mkNixShadowSetup pkgs);
              pathsToLink = [
                "/bin"
                "/etc"
              ];
            })
          ];
          config = {
            Env = [
              "NIX_PAGER=cat"
              "USER=${args.user}"
              "HOME=/"
            ];
          };
        };
    };
  };
}
