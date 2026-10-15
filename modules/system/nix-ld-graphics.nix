# Graphics libraries for prebuilt binaries run through nix-ld.
#
# Some downloaded tools link only libc and dlopen their graphics stack at
# runtime, so nix-ld's default library set (no Vulkan, no X11) leaves them
# without a window. deskplot, for one, fails xcb presentation with
# "BackendUnavailable" and drops to compute-only mode. Adds to the NixOS
# defaults rather than replacing them; the host still owns nix-ld.enable.
{ ... }:
{
  den.aspects.nix-ld-graphics.nixos =
    { pkgs, ... }:
    {
      programs.nix-ld.libraries = with pkgs; [
        vulkan-loader
        libxcb
      ];
    };
}
