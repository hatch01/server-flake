{
  config,
  hostName,
  lib,
  pkgs,
  mkSecrets,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  puppetFile = "/var/lib/matrix-synapse/puppet.yaml";
in {
  imports = [
    (import ./signal.nix {inherit config lib hostName;})
    (import ./discord.nix {inherit config lib hostName;})
    (import ./whatsapp.nix {inherit config lib hostName;})
  ];

  options = {
    matrix = {
      enable = mkEnableOption "enable matrix";
      enableElement = mkEnableOption "enable matrix element";
      hostName = mkOption {
        type = types.str;
        default = "matrix.${hostName}";
        description = "The hostname of the matrix instance";
      };
      port = mkOption {
        type = types.int;
        default = 8008;
      };
    };
  };

  config = mkIf config.matrix.enable {
    matrix.signal.enable = true;
    matrix.whatsapp.enable = true;
    matrix.discord.enable = true;

    age.secrets = mkSecrets {
      "matrix_oidc" = {
        owner = "matrix-synapse";
      };
      "matrix_shared_secret" = {
        owner = "matrix-synapse";
      };
    };

    systemd.services.matrix-synapse = {
      serviceConfig = {
        EnvironmentFile = config.age.secrets.matrix_shared_secret.path;
        SystemCallFilter = lib.mkForce ["@system-service"]; # making the service less secure to be able to modify files
      };
      preStart = lib.mkBefore ''
        test -f '${puppetFile}' && rm -f '${puppetFile}'
        ${pkgs.envsubst}/bin/envsubst \
            -o '${puppetFile}' \
            -i '${
          (pkgs.writeText "double-puppet.yaml" (lib.generators.toYAML {}
            {
              id = "puppet";
              url = "";
              as_token = "$SHARED_AS_TOKEN";
              hs_token = "somethingneveruserwedontcare";
              sender_localpart = "somethingneveruserwedontcare2";
              rate_limited = false;
              namespaces = {
                users = [
                  {
                    regex = "@.*:onyx\.ovh";
                    exclusive = false;
                  }
                ];
              };
            }))
        }'
      '';
    };

    services.matrix-synapse = {
      enable = true;

      # plugins = with config.services.matrix-synapse.package.plugins; [
      #   matrix-synapse-shared-secret-auth
      # ];

      settings.server_name = config.networking.domain;
      # The public base URL value must match the `base_url` value set in `clientConfig` above.
      # The default value here is based on `server_name`, so if your `server_name` is different
      # from the value of `fqdn` above, you will likely run into some mismatched domain names
      # in client applications.
      settings.public_baseurl = "https://${config.matrix.hostName}";
      settings.listeners = [
        {
          port = config.matrix.port;
          bind_addresses = ["::1"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = ["client" "federation"];
              compress = true;
            }
          ];
        }
      ];

      settings.app_service_config_files = [puppetFile];

      settings.oidc_providers = [
        {
          idp_id = "authelia";
          idp_name = "Authelia";
          idp_icon = "mxc://authelia.com/cKlrTPsGvlpKxAYeHWJsdVHI";
          discover = true;
          issuer = "https://${config.authelia.hostName}";
          client_id = "synapse";
          client_secret_path = config.age.secrets.matrix_oidc.path;
          scopes = ["openid" "profile" "email"];
          allow_existing_users = true;
          user_mapping_provider = {
            config = {
              subject_claim = "sub";
              localpart_template = "{{ user.preferred_username }}";
              display_name_template = "{{ user.name }}";
              email_template = "{{ user.email }}";
            };
          };
        }
      ];
    };

    postgres.initialScripts = [
      ''
        CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE
           = "C";''
    ];
    services.postgresql = {
      ensureUsers = [
        {
          name = "matrix-synapse";
        }
      ];
    };
  };
}
