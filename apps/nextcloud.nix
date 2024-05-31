{pkgs, config, ...}: {
  age = {
    identityPaths = ["/etc/age/key"];
    secrets = {
    nextcloudAdmin = {
      file = ../secrets/nextcloudAdmin.age;
      owner = "nextcloud";
    };
  };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "eymeric.eu";
    database.createLocally = true;
    config = {
      adminpassFile = config.age.secrets.nextcloudAdmin.path;
    };
  };
  networking.firewall.allowedTCPPorts = [80 443];
}
