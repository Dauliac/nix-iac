localflake:
{ ... }:
{
  imports = [
    (import ./packages.nix localflake)
    (import ./checks.nix localflake)
  ];
}
