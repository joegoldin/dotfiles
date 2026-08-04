# Per-virtual-desktop, per-monitor kwin tiling layouts. Machine-generated
# (UUIDs are this desktop's virtual desktops and monitors); captured from a
# live session, same as _plasma-panels.nix. Edit layouts in Plasma, then
# re-export, rather than hand-editing the JSON.
#
# Only groups for the current virtual desktop (003e92e5) are kept. KWin's
# kwinrc also accumulates dead groups -- old output-keyed v5 UUIDs whose JSON
# lost its bracket escaping, and groups for deleted virtual desktops. Those
# never match a live output/desktop again; drop them when re-exporting.
{ ... }:
{
  programs.plasma.configFile = {
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/1f2c90e2-3a8a-4a2e-831e-02e10fc958cd"."padding" =
      4;
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/1f2c90e2-3a8a-4a2e-831e-02e10fc958cd"."tiles" =
      ''{"layoutDirection":"horizontal","tiles":[{"width":1}]}'';
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/2fd71289-0069-4dd8-b8d9-85a14c65cd2e"."padding" =
      4;
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/2fd71289-0069-4dd8-b8d9-85a14c65cd2e"."tiles" =
      ''{"layoutDirection":"floating","tiles":[{"height":0.9879629629629629,"width":0.43697916666666664,"x":0.004687500000000001,"y":0.005555555555555555},{"height":0.9620370370370319,"width":0.8869791666666667,"x":0.0390625,"y":0.031481481481481485},{"height":0.9879629629629589,"width":0.4630208333333371,"x":0.4567708333333289,"y":0.005555555555555555}]}'';
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/3f40670c-5b6f-4904-835d-62d17f2324f5"."padding" =
      4;
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/3f40670c-5b6f-4904-835d-62d17f2324f5"."tiles" =
      ''{"layoutDirection":"floating","tiles":[{"height":0.9990740740740734,"width":0.49479166666666985,"x":0,"y":0},{"height":0.991666666666667,"width":0.9380208333333211,"x":0.030208333333335988,"y":0},{"height":0.9999999999999997,"width":0.49895833333333195,"x":0.5010416666666622,"y":2.94469310047063e-16}]}'';
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/71cde4f2-86c2-44dc-9896-c4c025c5c5fb"."padding" =
      4;
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/71cde4f2-86c2-44dc-9896-c4c025c5c5fb"."tiles" =
      ''{"layoutDirection":"floating","tiles":[{"height":0.8812499999999996,"width":0.9281249999999986,"x":0.04296875,"y":0.05},{"height":0.8819444444444443,"width":0.5832031250000012,"x":0.0191406249999989,"y":0.05972222222222237},{"height":0.9361111111111091,"width":0.374609374999996,"x":0.6171875,"y":0.02361111111111111},{"height":0.9354166666666647,"width":0.3953124999999972,"x":0.19648437500000618,"y":0.024305555555555594},{"height":0.7993055555555537,"width":0.32656250000000425,"x":0.42890625,"y":0.09791666666666662}]}'';
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/bd507e42-a7b4-4a0e-8871-ee8e19d10874"."padding" =
      4;
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/bd507e42-a7b4-4a0e-8871-ee8e19d10874"."tiles" =
      ''{"layoutDirection":"floating","tiles":[{"height":0.4848958333333333,"width":0.979629629629628,"x":0.011111111111110945,"y":0.010416666666666692},{"height":0.4520833333333334,"width":0.9703703703703689,"x":0.012962962962962671,"y":0.5182291666666666},{"height":0.9265624999999995,"width":0.9324074074074105,"x":0.03148148148148147,"y":0.035937500000000504}]}'';
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/cb342942-0add-40ec-ae28-abd51750b228"."padding" =
      4;
    "kwinrc"."Tiling/003e92e5-0a93-4e80-9e46-abcefff2f6ed/cb342942-0add-40ec-ae28-abd51750b228"."tiles" =
      ''{"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}'';
  };
}
