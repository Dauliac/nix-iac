localflake:
{ ... }:
{
  imports = [
    (import ./apps.nix localflake)
    (import ./checks.nix localflake)
    # (import ./dev-shell.nix localflake)
    (import ./packages.nix localflake)
  ];
}
