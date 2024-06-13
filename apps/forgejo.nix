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
    forgejo.enable = mkEnableOption "forgejo";
    forgejo.hostName = mkOption {
      type = types.str;
      default = "forge.${hostName}";
      description = "The hostname of the forgejo instance";
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
            HTTP_PORT = 3000;
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
      nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts = {
          "${config.forgejo.hostName}" = {
            locations."/".proxyPass = "http://localhost:3000";
          };
        };
      };
    };
    networking.firewall.allowedTCPPorts = [80 443];
  };
}