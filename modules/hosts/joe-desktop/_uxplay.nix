{ ... }:
{
  networking.firewall = {
    allowedTCPPorts = [ 7000 7001 7100 ];
    allowedUDPPorts = [ 5353 6000 6001 7011 ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
      workstation = true;
    };
  };
}
