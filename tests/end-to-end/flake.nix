{
  description = "Nix OCI tests";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nix-oci.url = "../../.";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      flake-parts,
      nix-oci,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (_: {
      imports = [
        inputs.nix-oci.modules.flake.default
      ];
      config = {
        oci.enabled = true;
        oci.fromImageManifestRootPath = ./.oci;
        systems = [
          "x86_64-linux"
        ];
        perSystem =
          {
            pkgs,
            config,
            ...
          }:
          {
            config.oci.containers = {
              hello = {
                package = pkgs.hello;
              };
              kubectl = {
                package = pkgs.kubectl;
                dependencies = [
                  pkgs.bash
                  pkgs.kubectl-cnpg
                ];
              };
              root = {
                name = "root";
                package = pkgs.bash;
                dependencies = [
                  pkgs.coreutils
                ];
                isRoot = true;
              };
              nix = {
                name = "nix";
                package = pkgs.bash;
                installNix = true;
                dependencies = [
                  pkgs.coreutils
                ];
                isRoot = true;
              };

              alpineFromRegistry = {
                fromImage = {
                  imageName = "library/alpine";
                  imageTag = "3.21.2";
                  os = "linux";
                  arch = "amd64";
                };
              };
              alpineWithTagOverride = {
                tag = "0.1.0";
                fromImage = {
                  imageName = "library/alpine";
                  imageTag = "3.21.2";
                  os = "linux";
                  arch = "amd64";
                };
              };
              alpineWithNameAndTagOverride = {
                name = "alpine-test";
                tag = "0.1.0";
                fromImage = {
                  imageName = "library/alpine";
                  imageTag = "3.21.1";
                  os = "linux";
                  arch = "amd64";
                };
              };
              alpineWithHelloNameAndTagOverride = {
                name = "alpine-test";
                tag = "0.1.0";
                package = pkgs.hello;
                fromImage = {
                  imageName = "library/alpine";
                  imageTag = "3.21.2";
                  os = "linux";
                  arch = "amd64";
                };
              };
            };
          };
      };
    });
}
