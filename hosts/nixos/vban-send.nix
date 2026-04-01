# VBAN send module - streams mic audio to office-pc (Windows) over Tailscale
{
  dotfiles-secrets,
  ...
}:
let
  domains = import "${dotfiles-secrets}/domains.nix";
in
{
  services.pipewire.extraConfig.pipewire."90-vban-send" = {
    "context.modules" = [
      {
        name = "libpipewire-module-vban-send";
        args = {
          "local.ifname" = "tailscale0";
          "destination.ip" = domains.officePcTailscale;
          "destination.port" = 6980;
          "net.ttl" = 64;
          "sess.name" = "Mic";
          "audio.format" = "S16LE";
          "audio.rate" = 48000;
          "audio.channels" = 1;
          "stream.props" = {
            "node.name" = "vban-mic-send";
            "node.description" = "VBAN Mic Send";
            "media.class" = "Audio/Sink";
          };
          "capture.props" = {
            "node.name" = "vban-mic-capture";
            "node.description" = "VBAN Mic Capture";
            "audio.position" = [ "MONO" ];
          };
        };
      }
    ];
  };
}
