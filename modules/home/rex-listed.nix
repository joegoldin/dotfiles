{ den, ... }:
{
  den.aspects.rex-listed = {
    includes = [ den.aspects.rex ];
    homeManager =
      { lib, ... }:
      {
        options.dotfiles.rex.listed = lib.mkOption {
          type = lib.types.bool;
          default = true;
          readOnly = true;
          internal = true;
          description = "Whether the host participates in the generated Rex host list.";
        };
      };
  };
}
