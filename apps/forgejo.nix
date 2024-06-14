# 👀 https://github.com/uku3lig/flake/blob/main/systems/etna/forgejo.nix
{
  config,
  hostName,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    forgejo = {
      enable = mkEnableOption "forgejo";
      hostName = mkOption {
        type = types.str;
        default = "forge.${hostName}";
        description = "The hostname of the forgejo instance";
      };
      port = mkOption {
        type = types.int;
        default = 3000;
        description = "The port on which forgejo will listen";
      };
    };
  };

  config = mkIf config.forgejo.enable {
    services = {
      openssh = {
        enable = true;
      };

      forgejo = {
        enable = true;
        database = {
          type = "postgres";
          createDatabase = true;
        };

        settings = {
          DEFAULT.APP_NAME = "Onyx Forge";

          server = {
            ROOT_URL = "http://${config.forgejo.hostName}";
            HTTP_PORT = config.forgejo.port;
          };

          service = {
            DISABLE_REGISTRATION = true;
            ENABLE_CAPTCHA = true;
          };

          oauth2 = {
            # providers are configured in the admin panel
            ENABLED = true;
          };

          actions.ENABLED = false;

          "ui.meta" = {
            AUTHOR = "The Onyx Forge Team";
            DESCRIPTION = "Where we forge the onyx stones";
          };

          "repository.signing" = {
            DEFAULT_TRUST_MODEL = "committer";
          };
        };
      };
    };
  };
}
