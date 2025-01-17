{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  config.perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      treefmt = {
        programs = {
          typos.enable = true;
          shellcheck.enable = true;
          nixfmt.enable = true;
          alejandra.enable = true;
          yamlfmt.enable = true;
          jsonfmt.enable = true;
          toml-sort.enable = true;
        };
      };
    };
}
