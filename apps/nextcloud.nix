{
  config,
  hostName,
  mkSecrets,
  mkSecret,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types optionalAttrs;
in {
  options = {
    nextcloud.enable = mkEnableOption "Nextcloud";
    nextcloud.hostName = mkOption {
      type = types.str;
      default = "nextcloud.${hostName}";
    };
    onlyoffice.enable = mkEnableOption "OnlyOffice";
    onlyoffice.hostName = mkOption {
      type = types.str;
      default = "onlyoffice.${hostName}";
    };
  };

  config = {
    age.secrets = mkSecrets {
      nextcloudAdmin = optionalAttrs true {
        owner = config.users.users.nextcloud.name;
        group = config.users.users.nextcloud.name;
      };
      onlyofficeKey = optionalAttrs true {
        owner = config.users.users.onlyoffice.name;
        group = config.users.users.onlyoffice.name;
      };
    };

    services = {
      nextcloud = mkIf config.nextcloud.enable {
        hostName = config.nextcloud.hostName;
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
        extraApps =
          {
            inherit
              (config.services.nextcloud.package.packages.apps)
              contacts
              calendar
              tasks
              mail
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
          }
          // mkIf config.onlyoffice.enable {
            inherit
              (config.services.nextcloud.package.packages.apps)
              onlyoffice
              ;
          };
        extraAppsEnable = true;
      };

      onlyoffice = mkIf config.onlyoffice.enable {
        enable = true;
        hostname = config.onlyoffice.hostName;
        jwtSecretFile = config.age.secrets.onlyofficeKey.path;
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
  };
}
