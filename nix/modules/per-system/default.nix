localflake:
{ ... }:
{
  imports = [
    (import ./packages.nix localflake)
    (import ./containers.nix localflake)
    (import ./internal localflake)
  ];
}
