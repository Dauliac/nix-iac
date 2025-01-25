localflake:
{ ... }:
{
  imports = [
    (import ./packages.nix localflake)
    (import ./checks.nix localflake)
    (import ./apps.nix localflake)
    (import ./dev-shell.nix localflake)
  ];
}
