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
    mkOption
    types
    mkEnableOption
    ;
in
{
  imports = [
    (import ./flake localflake)
    (import ./per-system localflake)
    (import ./sbom.nix localflake)
    (import ./cve.nix localflake)
    (import ./credentials-leak.nix localflake)
    (import ./test.nix localflake)
  ];
  options = {
    oci = {
      enabled = mkEnableOption "Enable the OCI module.";
      # TODO: move it into devShell submodule ?
      devShellPackage = mkOption {
        type = types.package;
        description = "The package to use for the dev shell.";
      };
      enableDevShell = mkOption {
        type = types.bool;
        description = "Enable the flake dev shell.";
        default = false;
      };
      rootPath = mkOption {
        type = types.path;
        default = self + "/oci/";
        description = "The root path to store the nix OCI resources.";
      };
      fromImageManifestRootPath = mkOption {
        type = types.path;
        default = cfg.oci.rootPath + "/pulledManifestsLocks/";
        description = "The root path to store the pulled OCI image manifest json lockfiles.";
      };
      registry = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The OCI registry to use for pushing and pulling images.";
      };
    };
  };
}
