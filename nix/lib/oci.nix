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
        in
        nix2container.pullImageFromManifest fromImage';
    };
    mkOCI = mkOption {
      description = mdDoc "A function to build container";
      type = types.functionTo types.package;
      default =
        args@{
          pkgs,
          nix2container,
          fromImageManifestRootPath,
          package ? null,
          isRoot ? false,
          installNix ? false,
          user ? "",
          tag ? "",
          name ? "",
          entrypoint ? [ ],
          dependencies ? [ ],
          fromImage ? { },
        }:
        let
          name =
            if args.name != null then
              if args.name == "" then throw "Empty name given" else args.name
            else if args.package != null then
              lib.strings.toLower args.package.meta.mainProgram
            else if args.fromImage != { } then
              lib.strings.toLower args.fromImage.imageName
            else if args.name == "" then
              throw "Empty name given"
            else
              throw "Error: No valid source for name (name, package.meta.mainProgram, or fromImage.imageName) found.";
          args' = args // {
            inherit name;
            user = if isRoot then "root" else name;
            tag =
              if package != null then
                package.version
              else if fromImage != { } then
                fromImage.imageTag
              else if tag == "" then
                throw "Empty tag given"
              else
                "1.0.0";
            entrypoint =
              if entrypoint != [ ] then
                entrypoint
              else if package != null then
                [
                  "/bin/${package.meta.mainProgram}"
                ]
              else
                [ ];
          };
        in
        if args.installNix then cfg.mkNixOCI args' else cfg.mkSimpleOCI args';
    };
    mkSimpleOCI = mkOption {
      description = mdDoc "A function to build simple container";
      type = types.functionTo types.package;
      default =
        args:
        (args.nix2container.buildImage {
          inherit (args) tag name;
          fromImage =
            if args.fromImage != { } then
              (cfg.mkOCIPulledManifestLock {
                inherit (args) nix2container fromImageManifestRootPath fromImage;
              })
            else
              "";
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
