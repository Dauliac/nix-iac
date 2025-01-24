{ ... }:
{
  config = {
    # config.oci.containerStructureTest.enabled = true;
    perSystem =
      {
        pkgs,
        config,
        ...
      }:
      {
        config.oci.containers = {
          minimalistWithContainerStructureTest = {
            package = pkgs.kubectl;
            containerStructureTest = {
              enabled = true;
              configs = [
                ./test.yaml
              ];
            };
          };
        };
      };
  };
}
