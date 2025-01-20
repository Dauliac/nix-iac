{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkOption
    mdDoc
    concatMapStrings
    concatStringsSep
    types
    ;
  cfg = config.lib;
in
{
  options.lib = {
    mkRoot = mkOption {
      description = mdDoc "A function to build container";
      type = types.functionTo types.package;
      default =
        {
          pkgs,
          tag,
          user ? null,
          package ? null,
          dependencies ? [ ],
        }:
        let
          package' = if package == null then [ ] else [ package ];
          shadowSetup =
            if user == "root" then
              cfg.mkRootShadowSetup { inherit pkgs; }
            else if user == null then
              [ ]
            else
              cfg.mkNonRootShadowSetup { inherit pkgs user; };
        in
        (pkgs.buildEnv {
          name = "root";
          version = tag;
          paths = package' ++ shadowSetup ++ dependencies;
          pathsToLink = [
            "/bin"
            "/lib"
            "/etc"
          ];
        });
    };
    mkNixConfig = mkOption {
      description = mdDoc "A function to build nix config";
      default =
        pkgs:
        pkgs.writeText "etc/nix/nix.conf" ''
          experimental-features = nix-command flakes
          build-users-group = nixbld
          sandbox = false
        '';
    };
    mkPublishOCIScript = mkOption {
      description = mdDoc "A function to build publishing script for ci";
      default =
        {
          container,
          pkgs,
        }:
        pkgs.writeScriptBin "publish-docker-image" ''
          #!${pkgs.bash}/bin/bash

          set -o errexit
          set -o nounset
          set -o pipefail

          main() {
            local -r image_path="$CI_REGISTRY_IMAGE/${container.imageName}:${container.imageTag}"

            echo "Authenticating to the registry..."
            echo "$CI_REGISTRY_PASSWORD" | ${pkgs.skopeo}/bin/skopeo login --username "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"

            echo "Pushing image $image_path to the registry..."
            ${pkgs.skopeo}/bin/skopeo copy \
              docker-archive:${container.outPath} \
              docker://$image_path
            echo "Image pushed to $image_path"
          }

          main "$@"
        '';
    };
    mkRootShadowSetup = mkOption {
      description = "A function to build passwd, shadow, group, and gshadow for containers run as root user.";
      default =
        { pkgs }:
        with pkgs;
        [
          (writeTextDir "etc/shadow" ''
            root:!x:::::::
          '')
          (writeTextDir "etc/passwd" ''
            root:x:0:0::/root:${runtimeShell}
          '')
          (writeTextDir "etc/group" ''
            root:x:0:
          '')
          (writeTextDir "etc/gshadow" ''
            root:x::
          '')
        ];
    };
    mkNonRootShadowSetup = mkOption {
      description = "A function to build passwd, shadow, group, and gshadow for containers run as non root user.";
      default =
        {
          user,
          pkgs,
          uid ? 4000,
          gid ? uid,
        }:
        with pkgs;
        [
          (writeTextDir "etc/shadow" ''
            root:!x:::::::
            ${user}:!:::::::
          '')
          (writeTextDir "etc/passwd" ''
            root:x:0:0::/root:${runtimeShell}
            ${user}:x:${toString uid}:${toString gid}::/home/${user}:
          '')
          (writeTextDir "etc/group" ''
            root:x:0:
            ${user}:x:${toString gid}:
          '')
          (writeTextDir "etc/gshadow" ''
            root:x::
            ${user}:x::
          '')
        ];
    };
    mkNixShadowSetup = mkOption {
      description = "A function to build passwd, shadow, group, and gshadow for containers that run nested nix in.";
      default =
        pkgs:
        let
          numBuildUsers = 32;
        in
        with pkgs;
        [
          writeText
          "etc/passwd"
          ''
            root:x:0:0:System administrator:/root:${pkgs.bash}/bin/bash
            nobody:x:65534:65534:Unprivileged account (don't use!):/var/empty:${pkgs.shadow}/bin/nologin
            ${concatMapStrings (nixbldIndex: ''
              nixbld${toString nixbldIndex}:x:${toString (30000 + nixbldIndex)}:30000:Nix build user ${toString nixbldIndex}:/var/empty:/bin/false
            '') (builtins.genList (nixbldIndex: nixbldIndex + 1) numBuildUsers)}
          ''
          writeText
          "etc/group"
          ''
            root:x:0:root
            nobody:x:65534:nobody
            nixbld:x:30000:${
              concatStringsSep "," (
                map (nixbldIndex: "nixbld${toString nixbldIndex}") (
                  builtins.genList (nixbldIndex: nixbldIndex + 1) numBuildUsers
                )
              )
            }
          ''
          writeText
          "etc/shadow"
          ''
            root:!x:::::::
            nobody:!:::::::
            ${concatMapStrings (nixbldIndex: ''
              nixbld${toString nixbldIndex}:!:::::::
            '') (builtins.genList (nixbldIndex: nixbldIndex + 1) numBuildUsers)}
          ''
          writeText
          "etc/gshadow"
          ''
            root:x::
            nobody:x::
            nixbld:x::
          ''
        ];
    };
  };
}
