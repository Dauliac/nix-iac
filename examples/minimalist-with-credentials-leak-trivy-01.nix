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
          minimalistWithTrivy = {
            package = pkgs.kubectl;
            credentialsLeak.trivy = {
              enabled = true;
            };
          };
        };
      };
  };
}
