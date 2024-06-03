{
  pkgs,
  config,
  ...
}: {
  age = {
    identityPaths = ["/etc/age/key"];
    secrets = {
      nextcloudAdmin = {
        file = ../secrets/nextcloudAdmin.age;
        owner = "nextcloud";
      };
    };
  };

  services = {
    nextcloud = {
      enable = true;
      # package = pkgs.nextcloud29;
      hostName = "eymeric.eu";
      autoUpdateApps.enable = true;
      # https = true; # TODO when we have dns
      configureRedis = true;
      # datadir = ""; # probably needed with raid disk etc
      database.createLocally = true;
      config = {
        adminpassFile = config.age.secrets.nextcloudAdmin.path;
        dbtype = "pgsql";
      };
    };
  };

  # when we have dns
  #   services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
  #   forceSSL = true;
  #   enableACME = true;
  # };

  # security.acme = {
  #   acceptTerms = true;
  #   certs = {
  #     ${config.services.nextcloud.hostName}.email = "your-letsencrypt-email@example.com";
  #   };
  # };

  networking.firewall.allowedTCPPorts = [80 443];
}
