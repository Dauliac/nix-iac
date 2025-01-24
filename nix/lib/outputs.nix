{ lib, ... }:
let
  inherit (lib)
    attrsets
    foldl'
    mdDoc
    mkOption
    ;
in
{
  options.lib = {
    prefixOutputs = mkOption {
      description = mdDoc "A prefix to add to the output file.";
      default =
        {
          prefix,
          set,
        }:
        foldl' (
          acc: id:
          acc
          // {
            "${prefix}${id}" = set.${id};
          }
        ) { } (attrsets.attrNames set);
    };
    filterEnabledOutputsSet = mkOption {
      description = mdDoc "A function to filter outputs.";
      default =
        {
          config,
          subConfig,
        }:
        let
          subConfigPath = lib.splitString "." subConfig;
        in
        attrsets.filterAttrs (
          id: value:
          let
            subConfigValue = lib.attrByPath subConfigPath null value;
          in
          subConfigValue != null && subConfigValue.enabled == true
        ) config;
    };
  };
}
