localflake:
{
  config,
  lib,
  inputs,
  self,
  ...
}:
let
  localLib = localflake.config.lib;
  cfg = config;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
in
{
  options = {
    perSystem = inputs.flake-parts.lib.mkPerSystemOption (
      {
        config,
        pkgs,
        system,
        ...
      }:
      {
        options.oci.containers = mkOption {
          type = types.attrsOf (
            types.submodule (
              { name, ... }:
              {
                options = {
                  tag = mkOption {
                    type = types.nullOr types.str;
                    description = "Tag of the container.";
                    default = localLib.mkOCITag {
                      inherit (config.oci.containers.${name}) package fromImage;
                    };
                  };
                  dive = mkOption {
                    default = { };
                    type = types.submodule {
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          description = "Whether to run dive.";
                          default = cfg.oci.dive.enabled;
                        };
                      };
                    };
                  };
                  containerStructureTest = mkOption {
                    default = { };
                    type = types.submodule {
                      options = {
                        enabled = mkOption {
                          type = types.bool;
                          description = "Whether to run container-structure-test.";
                          default = cfg.oci.containerStructureTest.enabled;
                        };
                        configs = mkOption {
                          type = types.listOf types.path;
                          description = "The container-structure-test configs file to run.";
                          default = [ ];
                        };
                      };
                    };
                  };
                  credentialsLeak = mkOption {
                    description = ".";
                    default = { };
                    type = types.submodule {
                      options = {
                        trivy = mkOption {
                          description = "The package to use for the cve check.";
                          default = { };
                          type = types.submodule {
                            options = {
                              enabled = mkOption {
                                type = types.bool;
                                description = "";
                                default = cfg.oci.cve.trivy.enabled;
                              };
                            };
                          };
                        };
                      };
                    };
                  };
                  sbom = mkOption {
                    description = ".";
                    default = { };
                    type = types.submodule {
                      options = {
                        syft = mkOption {
                          description = "";
                          default = { };
                          type = types.submodule {
                            options = {
                              enabled = mkOption {
                                type = types.bool;
                                description = "";
                                default = cfg.oci.sbom.syft.enabled;
                              };
                              config = mkOption {
                                description = "";
                                default = { };
                                type = types.submodule {
                                  options = {
                                    enabled = mkOption {
                                      type = types.bool;
                                      description = "";
                                      default = cfg.oci.sbom.syft.config.enabled;
                                    };
                                    path = mkOption {
                                      type = types.path;
                                      description = "";
                                      default = cfg.oci.sbom.syft.config.rootPath + name + ".yaml";
                                    };
                                  };
                                };
                              };
                            };
                          };
                        };
                      };
                    };
                  };
                  cve = mkOption {
                    description = "Whether to check for CVEs.";
                    default = { };
                    type = types.submodule {
                      options = {
                        trivy = mkOption {
                          description = "The package to use for the cve check.";
                          default = { };
                          type = types.submodule {
                            options = {
                              enabled = mkOption {
                                type = types.bool;
                                description = "";
                                default = cfg.oci.cve.trivy.enabled;
                              };
                              ignore = mkOption {
                                description = "";
                                default = { };
                                type = types.submodule {
                                  options = {
                                    fileEnabled = mkEnableOption "";
                                    path = mkOption {
                                      type = types.nullOr types.path;
                                      description = "";
                                      default = cfg.oci.cve.trivy.ignore.rootPath + name + ".ignore";
                                    };
                                    extra = mkOption {
                                      type = types.listOf types.str;
                                      description = "Extra CVE to ignore.";
                                      default = [ ];
                                    };
                                  };
                                };
                              };
                            };
                          };
                        };
                        grype = mkOption {
                          description = "";
                          default = { };
                          type = types.submodule {
                            options = {
                              enabled = mkOption {
                                type = types.bool;
                                description = "Whether to run grype.";
                                default = cfg.oci.cve.grype.enabled;
                              };
                              config = mkOption {
                                description = "The path to the grype config.";
                                default = { };
                                type = types.submodule {
                                  options = {
                                    enabled = mkOption {
                                      type = types.bool;
                                      description = "";
                                      default = cfg.oci.cve.grype.config.enabled;
                                    };
                                    path = mkOption {
                                      type = types.path;
                                      description = "";
                                      default = cfg.oci.cve.grype.config.rootPath + name + ".yaml";
                                    };
                                  };
                                };
                              };
                            };
                          };
                        };
                      };
                    };
                  };
                  package = mkOption {
                    type = types.nullOr types.package;
                    description = "The main package for the container";
                    default = null;
                  };
                  name = mkOption {
                    type = types.nullOr types.str;
                    description = "Name of the container by default values are generated from the package  or given name.";
                    default = localLib.mkOCIName {
                      inherit (config.oci.containers.${name}) package fromImage;
                    };
                  };
                  user = mkOption {
                    type = types.nullOr types.str;
                    description = "The user to run the container as.";
                    default = localLib.mkOCIUser {
                      inherit (config.oci.containers.${name}) name isRoot;
                    };
                  };
                  fromImage = mkOption {
                    description = "The image to use as the base image.";
                    type = types.nullOr (
                      types.submodule (
                        { ... }:
                        {
                          options = {
                            imageName = mkOption {
                              type = types.nullOr types.str;
                              description = "The name of the base image.";
                              example = "library/alpine";
                              default = null;
                            };
                            imageTag = mkOption {
                              type = types.str;
                              description = "The tag/version of the image.";
                              example = "3.21.2";
                            };
                            os = mkOption {
                              type = types.enum [
                                "linux"
                              ];
                              description = "The operating system for the image.";
                              example = "linux";
                              default = "linux";
                            };
                            arch = mkOption {
                              type = types.enum [
                                "amd64"
                                "arm64"
                              ];
                              description = "The architecture of the image.";
                              example = "amd64";
                              default =
                                if system == "x86_64-linux" then
                                  "amd64"
                                else if system == "aarch64-linux" then
                                  "arm64"
                                else
                                  throw "Unsupported system: ${system} as default arch, please set the arch option.";
                            };
                          };
                        }
                      )
                    );
                    default = null;
                    example = {
                      imageName = "library/alpine";
                      imageTag = "1.2.3";
                      os = "linux";
                      arch = "amd64";
                    };
                  };
                  dependencies = mkOption {
                    type = types.listOf types.package;
                    description = "Additional dependencies packages to include in the container.";
                    default = [ ];
                  };
                  isRoot = mkOption {
                    type = types.bool;
                    description = "Whether the container is a root container.";
                    default = false;
                  };
                  installNix = mkOption {
                    type = types.bool;
                    description = "Whether to install nix in the container.";
                    default = false;
                  };
                  push = mkOption {
                    type = types.bool;
                    description = "Whether to push the container to the OCI registry.";
                    default = false;
                  };
                  entrypoint = mkOption {
                    type = types.listOf types.str;
                    description = "The entrypoint for the container.";
                    default = localLib.mkOCIEntrypoint { inherit (config.oci.containers.${name}) package; };
                  };
                };
              }
            )
          );
          description = "Definitions for all containers.";
          default = { };
          example = {
            package = pkgs.hello;
            dependencies = [ pkgs.bash ];
          };
        };
      }
    );
  };
}
