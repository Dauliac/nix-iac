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
              open-policy-agent
              trivy
              vulnix
              dive
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
