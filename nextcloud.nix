{config, ...}:
{
services.nextcloud = {
  enable = true;
  hostName="eymeric.eu";
  database.createLocally = true;
  config = {
   adminpassFile = "/etc/nixos/adminpass";
  };
};
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
