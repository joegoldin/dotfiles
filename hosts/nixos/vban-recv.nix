# VBAN recv module - receives audio from office-pc (Windows) over Tailscale
{
  networking.firewall.allowedUDPPorts = [ 6981 ];

  services.pipewire.extraConfig.pipewire."91-vban-recv" = {
    "context.modules" = [
      {
        name = "libpipewire-module-vban-recv";
        args = {
          "local.ifname" = "tailscale0";
          "source.port" = 6981;
          "sess.name" = "OfficePC";
          "audio.format" = "S16LE";
          "audio.rate" = 48000;
          "audio.channels" = 2;
          "stream.props" = {
            "node.name" = "vban-office-recv";
            "node.description" = "VBAN Office PC";
            "media.class" = "Audio/Source";
          };
          "playback.props" = {
            "node.name" = "vban-office-playback";
            "node.description" = "VBAN Office PC Playback";
            "audio.position" = [
              "FL"
              "FR"
            ];
          };
        };
      }
    ];
  };
}
