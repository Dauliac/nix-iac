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
        oci.containers = {
          toto = {
            tag = "0.1.0";
            package = pkgs.cypress;
            dependencies = [
              pkgs.bash
              pkgs.firefox
              pkgs.nacl
            ];
            isRoot = true;
          };
        };
      };
  };
}
