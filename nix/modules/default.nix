localflake:
{ ... }:
{
  imports = [
    (import ./config localflake)
    (import ./options localflake)
  ];
}
