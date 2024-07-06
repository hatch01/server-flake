{
  config,
  hostName,
  lib,
  mkSecret,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
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
    age.secrets = mkSecret "matrix_oidc" {
      owner = "matrix-synapse";
    };

    services.matrix-synapse = {
      enable = true;
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
    # services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
    #   CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
    #     TEMPLATE template0
    #     LC_COLLATE = "C"
    #     LC_CTYPE = "C";
    # '';
    services.postgresql = {
      # ensureDatabases = ["matrix-synapse"];
      ensureUsers = [
        {
          name = "matrix-synapse";
          # ensureDBOwnership = true;
        }
      ];
    };
  };
}
