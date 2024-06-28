{
  lib,
  config,
  hostName,
  mkSecrets,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf optionals types;
  autheliaInstance = "main";
  mkUserRule = appName:
    optionals config."${appName}".enable [
      {
        domain = config."${appName}".hostName;
        policy = "one_factor";
        networks = ["local"];
      }
      {
        domain = config."${appName}".hostName;
        policy = "two_factor";
      }
    ];
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

  disabledModules = [
    "services/security/authelia.nix"
  ];
  imports = [
    "${inputs.authelia}/nixos/modules/services/security/authelia.nix"
  ];

  config = mkIf config.authelia.enable {
    age.secrets = let
      cfg = {
        owner = "authelia";
        group = "authelia";
      };
    in
      mkSecrets {
        "authelia/storageKey" = cfg;
        "authelia/jwtKey" = cfg;
        "authelia/authBackend" = cfg;
        "authelia/oAuth2PrivateKey" = cfg;
      };
    users = {
      users.authelia = {
        isSystemUser = true;
        group = "authelia";
        extraGroups = ["smtp"];
      };
      groups.authelia = {};
    };

    systemd.services.authelia = {
      after = ["postgresql.service"];
    };
    systemd.services."authelia-${autheliaInstance}" = {
      environment = {
        # needed to set the secrets using agenix see: https://www.authelia.com/configuration/methods/files/#file-filters
        X_AUTHELIA_CONFIG_FILTERS = "template";
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.smtpPassword.path;
      };
    };

    services = {
      authelia.instances = {
        "${autheliaInstance}" = {
          enable = true;
          package = pkgs.prs.authelia;
          user = "authelia";
          group = "authelia";

          secrets = {
            storageEncryptionKeyFile = config.age.secrets."authelia/storageKey".path;
            jwtSecretFile = config.age.secrets."authelia/jwtKey".path;
          };

          settingsFiles = [
            # neet to write this in plain text because nix to yaml is doing some weird stuff
            # see https://github.com/NixOS/nixpkgs/pull/299309 for details
            (builtins.toFile
              "authelia_id_provider_key.yaml"
              ''                identity_providers:
                  oidc:
                    jwks:
                    - key: {{ secret "/run/agenix/authelia/oAuth2PrivateKey" | mindent 10 "|" | msquote }}'')
          ];

          settings = {
            theme = "auto";

            default_2fa_method = "webauthn";
            webauthn = {
              disable = false;
              display_name = "Authelia";
              attestation_conveyance_preference = "indirect";
              user_verification = "preferred";
              timeout = "60s";
            };

            totp = {
              disable = false;
              issuer = "authelia.com";
              algorithm = "sha1";
              digits = 6;
              period = 30;
              skew = 1;
              secret_size = 32;
              allowed_algorithms = ["SHA1"];
              allowed_digits = [6];
              allowed_periods = [30];
              disable_reuse_security_policy = false;
            };

            # TODO add duo configuration later

            server = {
              disable_healthcheck = true;
              address = "tcp://:${toString config.authelia.port}/";
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
              keep_stdout = true;
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
            notifier = {
              disable_startup_check = false;
              smtp = {
                # using 587 port which is unencrypted I know but did not manage to make it working with 465
                # however this is very unprobable that someone will sniff the network
                address = "smtp://smtp.free.fr:587";
                timeout = "60s";
                username = "eymeric.monitoring";
                sender = "Authelia <authelia@onyx.ovh>";
                subject = "[Authelia] {title}";
                startup_check_address = "eymericdechelette@gmail.com";
                disable_require_tls = false;
                disable_starttls = false;
                disable_html_emails = false;
              };
            };

            access_control = {
              default_policy = "deny";
              networks = [
                {
                  name = "local";
                  networks = ["192.168.0.0/18"];
                }
              ];
              rules =
                [
                  # be careful with the order of the rules it is important
                  # https://www.authelia.com/configuration/security/access-control/#rule-matching
                  {
                    domain_regex = ".*\.${hostName}";
                    policy = "one_factor";
                    networks = ["local"];
                    subject = [
                      ["group:admin"]
                    ];
                  }
                  {
                    domain_regex = ".*\.${hostName}";
                    policy = "two_factor";
                    subject = [
                      ["group:admin"]
                    ];
                  }
                ]
                ++ mkUserRule "homepage";
            };

            authentication_backend = {
              file = {
                # a agenix managed yaml doc : https://www.authelia.com/reference/guides/passwords/#yaml-format
                path = config.age.secrets."authelia/authBackend".path;
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

            identity_providers.oidc = {
              # enable to make it working so using settingsFiles (look above)
              # jwks = [
              #   {
              #     key_id = "main";
              #     key = ''{{ secret "${config.age.secrets."authelia/oAuth2PrivateKey".path}" | mindent 10 "|" | msquote }}'';
              #   }
              # ];
              clients =
                []
                ++ optionals config.nextcloud.enable [
                  {
                    client_name = "NextCloud";
                    client_id = "nextcloud";
                    # the client secret is a random hash so don't worry about it
                    client_secret = "$pbkdf2-sha512$310000$NqCsT52TLWKH2GOq1c7vyw$ObxsUBEcwK53BY8obKj7fjmk1xp4MnTYCc2kS9UKpKifVGOQczt4rQx0bWt5pInqpAKxGHXo/RGa7DolDugz2A";
                    public = false;
                    authorization_policy = "two_factor";
                    require_pkce = true;
                    pkce_challenge_method = "S256";
                    redirect_uris = ["https://${config.nextcloud.hostName}/apps/oidc_login/oidc"];
                    scopes = [
                      "openid"
                      "profile"
                      "email"
                      "groups"
                    ];
                    userinfo_signed_response_alg = "none";
                    token_endpoint_auth_method = "client_secret_basic";
                  }
                ]
                ++ optionals config.gitlab.enable [
                  {
                    client_name = "GitLab";
                    client_id = "gitlab";
                    # the client secret is a random hash so don't worry about it
                    client_secret = "$pbkdf2-sha512$310000$rSqyDXxdbAKVa46e7tdWWg$Go0EtABXJpe9oJuJboomLc/g31Dho5QqT3Hs954WPAYLKv2GKmPlclvPZb.0tq1dLVQHBbOG66hQvFh1kpOt7g";
                    public = false;
                    authorization_policy = "two_factor";
                    require_pkce = true;
                    pkce_challenge_method = "S256";
                    redirect_uris = ["https://${config.gitlab.hostName}/users/auth/openid_connect/callback"];
                    scopes = [
                      "openid"
                      "profile"
                      "groups"
                      "email"
                    ];
                    userinfo_signed_response_alg = "none";
                    token_endpoint_auth_method = "client_secret_basic";
                  }
                ];
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
