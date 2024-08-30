{
  config,
  hostName,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    matrix = {
      discord = {
        enable = mkEnableOption "enable matrix";
      };
    };
  };

  config = mkIf config.matrix.discord.enable {
    services.mautrix-discord = {
      enable = true;
      registerToSynapse = true;
      settings = {
        bridge = {
          permissions = {
            "*" = "relay";
            "${hostName}" = "user";
            "@root:${hostName}" = "admin";
          };
          login_shared_secret_map = {
            "${hostName}" = "as_token:$SHARED_AS_TOKEN";
          };
        };
        homeserver = {
          address = "http://localhost:${toString config.matrix.port}";
          domain = config.networking.domain;
        };
        appservice = {
          database = {
            type = "postgres";
            uri = "postgresql:///mautrix-discord?host=/run/postgresql";
          };
        };
      };
      environmentFile = config.age.secrets.matrix_shared_secret.path;
    };
    postgres.initialScripts = [
      ''
        CREATE ROLE "mautrix-discord" WITH LOGIN PASSWORD 'discord';
        ALTER ROLE "mautrix-discord" WITH LOGIN;
        CREATE DATABASE "mautrix-discord" WITH OWNER "mautrix-discord"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C";''
    ];
  };
}
