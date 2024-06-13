{
  lib,
  config,
  hostName,
  mkSecrets,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    authelia.enable = mkEnableOption "enable Authelia";
    authelia.hostName = mkOption {
      type = types.str;
      default = "authelia.${hostName}";
      description = "The hostname of the Authelia instance";
    };
  };
  config = mkIf config.authelia.enable {
    age.secrets = let
      cfg = {
        owner = "authelia";
        group = "authelia";
      };
    in
      mkSecrets {
        autheliaStorageKey = cfg;
        autheliaJwtKey = cfg;
        autheliaAuthBackend = cfg;
      };
    users = {
      users.authelia = {
        isSystemUser = true;
        group = "authelia";
      };
      groups.authelia = {};
    };

    services = {
      authelia.instances = {
        main = {
          enable = true;
          user = "authelia";
          group = "authelia";
          secrets.storageEncryptionKeyFile = config.age.secrets.autheliaStorageKey.path;
          secrets.jwtSecretFile = config.age.secrets.autheliaJwtKey.path;
          settings = {
            theme = "auto";
            default_2fa_method = "webauthn";
            server.disable_healthcheck = true;
            log = {
              format = "text"; # for fail2ban better integration
              file_path = "/var/log/authelia.log";
              keep_stdout = true; # TODO remove after debug
              level = "debug"; # TODO switch to trace after debug
            };
            server.port = 9091;
            # storage use postgres later https://www.authelia.com/configuration/storage/introduction/
            # https://www.authelia.com/configuration/storage/postgres/

            # notifier needed for 2FA and email
            # https://www.authelia.com/configuration/notifications/introduction/
            access_control = {
              default_policy = "deny";
              # TODO add rule for local network to bypass 2FA
              rules = [
                {
                  domain = "*.${hostName}";
                  policy = "one_factor";
                }
              ];
            };
            authentication_backend = {
              file = {
                # TODO switch to a age managed yaml config https://www.authelia.com/reference/guides/passwords/#yaml-format
                # path =
                watch = true;
                # letting password hashing settings to the default (argon2id)
              };
            };
          };
        };
      };

      nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts = {
          "${config.authelia.hostName}" = {
            locations."/".proxyPass = "http://localhost:9091";
          };
        };
      };
    };
  };
}
