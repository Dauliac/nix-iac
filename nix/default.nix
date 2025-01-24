{
  inputs,
  config,
  ...
}:
let
  inherit (inputs.flake-parts.lib) importApply;
  flakeModules = importApply ./modules {
    inherit inputs;
    inherit config;
  };
in
{
  imports = [
    ./lib
    ./treefmt.nix
    ./examples.nix
    inputs.flake-parts.flakeModules.modules
    flakeModules
  ];
  config = {
    oci.enabled = true;
    flake.modules.flake.default = flakeModules;
    flake.modules.flake.nix-oci = flakeModules;
    perSystem =
      {
        config,
        pkgs,
        inputs',
        ...
      }:
      {
        devShells.default = pkgs.mkShell {
          packages =
            with pkgs;
            [
              cosign # TODO: implement cosign script generation
              conftest # TODO:: implement it
              trivy # TODO use config package
              dive # TODO use config package
              syft # TODO use config package
              grype # TODO use config package
              podman # TODO use config package
              container-structure-test # TODO use config package
              docker-slim # TODO: check if we can implement it
              dgoss # Implement it
              bats
              parallel
              lefthook
              convco
            ]
            ++ [
              inputs'.nix2container.packages.skopeo-nix2container
            ];
          shellHook = ''
            ${pkgs.lefthook}/bin/lefthook install --force
          '';
        };
      };
  };
}
