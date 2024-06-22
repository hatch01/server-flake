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
    users.users.forgejo.extraGroups = ["forgejo" "smtp"];

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

        mailerPasswordFile = config.age.secrets.smtpPassword.path;

        settings = {
          DEFAULT.APP_NAME = "Onyx Forge";

          server = {
            ROOT_URL = "https://${config.forgejo.hostName}";
            HTTP_PORT = config.forgejo.port;
          };

          openid = {
            ENABLE_OPENID_SIGNIN = false;
            ENABLE_OPENID_SIGNUP = true;
            WHITELISTED_URIS = config.authelia.hostName;
          };

          service = {
            DISABLE_REGISTRATION = false;
            ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
            SHOW_REGISTRATION_BUTTON = false;
            ENABLE_CAPTCHA = true;
          };

          mailer = {
            ENABLED = true;
            PROTOCOL = "smtps";
            FORCE_TRUST_SERVER_CERT = true;
            SMTP_ADDR = "smtp.free.fr";
            SMTP_PORT = 587;
            USER = "eymeric.monitoring";
            FROM = "ForgeJo <forgejo@onyx.ovh>";
            # PASSWD = "#0LtshV_vAe1%*tU";
            # ENVELOPE_FROM = "<>";
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
