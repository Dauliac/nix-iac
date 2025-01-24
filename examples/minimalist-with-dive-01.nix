{ ... }:
{
  config = {
    perSystem =
      {
        pkgs,
        config,
        ...
      }:
      {
        config.oci.containers = {
          minimalistWithDive = {
            package = pkgs.kubectl;
            dive.enabled = true;
          };
        };
      };
  };
}
