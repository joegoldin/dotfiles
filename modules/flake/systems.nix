# Systems flake-parts evaluates perSystem outputs for (packages, checks,
# devShells, formatter). Same set the legacy eachSystem used.
{ inputs, ... }:
{
  systems = import inputs.systems;
}
