{
  lib,
  config,
  hostName,
  mkSecrets,
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

    systemd.services.authelia = {
      after = ["postgresql.service"];
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
            server.port = 9091;
            log = {
              format = "text"; # for fail2ban better integration
              file_path = "/tmp/authelia.log"; # TODO modify to /var/log/authelia.log or something else
              keep_stdout = true; # TODO remove after debug
              level = "debug"; # TODO switch to trace after debug
            };
            storage = {
              postgres = {
                host = "/run/postgresql";
                inherit (config.services.postgresql) port;
                database = "authelia";
                username = "authelia";
                password = "anUnus3dP@ssw0rd"; # thanks copilot for this beautiful password
              };
            };

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
                # a agenix managed yaml doc : https://www.authelia.com/reference/guides/passwords/#yaml-format
                path = config.age.secrets.autheliaAuthBackend.path;
                # watch = true;
                # letting password hashing settings to the default (argon2id)
              };
            };

            session = {
              domain = hostName;
            };

            notifier = {
              filesystem = {
                filename = "/tmp/notifier";
              };
            };
          };
        };
      };

      postgresql = {
        enable = true;
        ensureDatabases = ["authelia"];
        ensureUsers = [
          {
            name = "authelia";
            ensureDBOwnership = true;
          }
        ];
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
