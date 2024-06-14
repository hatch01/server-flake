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
    authelia = {
      enable = mkEnableOption "enable Authelia";
      hostName = mkOption {
        type = types.str;
        default = "authelia.${hostName}";
        description = "The hostname of the Authelia instance";
      };
      port = mkOption {
        type = types.int;
        default = 9091;
        description = "The port on which Authelia will listen";
      };
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
          package = pkgs.prs.authelia;
          user = "authelia";
          group = "authelia";
          secrets.storageEncryptionKeyFile = config.age.secrets.autheliaStorageKey.path;
          secrets.jwtSecretFile = config.age.secrets.autheliaJwtKey.path;
          settings = {
            theme = "auto";
            default_2fa_method = "webauthn";
            server = {
              disable_healthcheck = true;
              # address = "localhost:${toString config.authelia.port}";
              port = config.authelia.port; # TODO migrate to address
              endpoints = {
                authz = {
                  auth-request = {
                    implementation = "AuthRequest";
                  };
                };
              };
            };
            log = {
              format = "text"; # for fail2ban better integration
              file_path = "/tmp/authelia.log"; # TODO modify to /var/log/authelia.log or something else
              keep_stdout = true; # TODO remove after debug
              level = "debug"; # TODO switch to trace after debug
            };
            storage = {
              postgres = {
                address = "/run/postgresql";
                database = "authelia";
                username = "authelia";
                password = "anUnus3dP@ssw0rd"; # thanks copilot for this beautiful password
              };
            };

            # notifier needed for 2FA and email
            # https://www.authelia.com/configuration/notifications/introduction/
            access_control = {
              default_policy = "deny";
              networks = [
                {
                  name = "local";
                  networks = ["192.168.0.0/18"];
                }
              ];
              # TODO add rule for local network to bypass 2FA
              rules = [
                {
                  domain = "*.${hostName}";
                  policy = "one_factor";
                  networks = ["local"];
                }
                {
                  domain = "*.${hostName}";
                  policy = "two_factor";
                }
                {
                  domain = hostName;
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
              cookies = [
                {
                  domain = hostName;
                  authelia_url = "https://${config.authelia.hostName}";
                  default_redirection_url = "https://${hostName}";
                }
              ];
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
