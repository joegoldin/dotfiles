# iOS devices over USB: usbmuxd for pairing and transport, the idevice* tools,
# and ifuse for mounting app/media storage.
{ ... }:
{
  den.aspects.elphael.nixos =
    { pkgs, ... }:
    {
      services.usbmuxd.enable = true;

      environment.systemPackages = with pkgs; [
        ifuse
        libimobiledevice
      ];
    };
}
