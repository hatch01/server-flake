{
  pkgs,
  config,
  hostName,
  ...
}: {
  age = {
    identityPaths = ["/etc/age/key"];
    secrets = {
      nextcloudAdmin = {
        file = ../secrets/nextcloudAdmin.age;
        owner = "nextcloud";
      };
      onlyofficeKey.file = ../secrets/onlyofficeKey.age;
    };
  };

  services = {
    nextcloud = {
      inherit hostName;
      enable = true;
      # package = pkgs.nextcloud29;
      autoUpdateApps.enable = true;
      # https = true; # TODO when we have dns
      configureRedis = true;
      # datadir = ""; # probably needed with raid disk etc
      database.createLocally = true;
      maxUploadSize = "10G";
      config = {
        adminpassFile = config.age.secrets.nextcloudAdmin.path;
        dbtype = "pgsql";
      };

      # apps
      extraApps = {
        inherit
          (config.services.nextcloud.package.packages.apps)
          contacts
          calendar
          tasks
          mail
          onlyoffice
          twofactor_webauthn
          cospend
          end_to_end_encryption
          forms
          groupfolders
          maps
          music
          notes
          previewgenerator
          spreed
          deck
          cookbook
          ;
      };
      extraAppsEnable = true;
    };

    onlyoffice = {
      enable = true;
      hostname = "onlyoffice.${hostName}";
      # jwtSecretFile = config.age.secrets.onlyofficeKey.path;
    };
  };

  environment.sessionVariables = {
    ALLOW_META_IP_ADDRESS = "true";
    ALLOW_PRIVATE_IP_ADDRESS = "true";
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
}
