{pkgs, ...}: {
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "eymeric.eu";
    database.createLocally = true;
    config = {
      adminpassFile = "/etc/nixos/adminpass";
    };
  };
  networking.firewall.allowedTCPPorts = [80 443];
}
