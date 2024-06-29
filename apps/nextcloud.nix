{
  config,
  hostName,
  mkSecrets,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types optionalAttrs;
in {
  options = {
    nextcloud = {
      enable = mkEnableOption "Nextcloud";
      hostName = mkOption {
        type = types.str;
        default = "nextcloud.${hostName}";
      };
      port = mkOption {
        type = types.int;
        default = 443;
      };
    };
    onlyoffice.enable = mkEnableOption "OnlyOffice";
    onlyoffice.hostName = mkOption {
      type = types.str;
      default = "onlyoffice.${hostName}";
    };
  };

  config = {
    age.secrets = mkSecrets {
      nextcloudAdmin = optionalAttrs config.nextcloud.enable {
        owner = config.users.users.nextcloud.name;
        group = config.users.users.nextcloud.name;
      };
      nextcloudSecretFile = optionalAttrs config.nextcloud.enable {
        owner = config.users.users.nextcloud.name;
        group = config.users.users.nextcloud.name;
      };
      onlyofficeKey = optionalAttrs config.onlyoffice.enable {
        owner = config.users.users.onlyoffice.name;
        group = config.users.users.onlyoffice.name;
      };
    };

    services = {
      nextcloud = mkIf config.nextcloud.enable {
        hostName = config.nextcloud.hostName;
        enable = true;
        # package = pkgs.nextcloud29;
        autoUpdateApps.enable = true;
        https = true;
        configureRedis = true;
        # datadir = ""; # probably needed with raid disk etc
        database.createLocally = true;
        maxUploadSize = "10G";
        config = {
          adminpassFile = config.age.secrets.nextcloudAdmin.path;
          dbtype = "pgsql";
        };

        # apps
        extraApps =
          {
            inherit
              (config.services.nextcloud.package.packages.apps)
              contacts
              calendar
              tasks
              mail
              twofactor_webauthn
              cospend
              end_to_end_encryption
              forms
              groupfolders
              maps
              music
              notes
              previewgenerator
              spreed
              deck
              cookbook
              ;
          }
          // mkIf config.authelia.enable {
            oidc_login = pkgs.fetchNextcloudApp {
              license = "agpl3Plus";
              url = "https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v3.1.1/oidc_login.tar.gz";
              sha256 = "sha256-EVHDDFtz92lZviuTqr+St7agfBWok83HpfuL6DFCoTE=";
            };
          }
          // mkIf config.onlyoffice.enable {
            inherit
              (config.services.nextcloud.package.packages.apps)
              onlyoffice
              ;
          };
        extraAppsEnable = true;
        # appstoreEnable = true; # DO NOT ENABLE, it will break the declarative config for apps

        settings =
          {
            mail_from_address = "nextcloud";
            mail_smtpmode = "smtp";
            mail_sendmailmode = "smtp";
            mail_domain = "onyx.ovh";
            mail_smtphost = "mtp.free.fr";
            mail_smtpauth = 1;
            mail_smtpport = 587;
            mail_smtpname = "eymeric.monitoring";
          }
          // mkIf config.authelia.enable {
            user_oidc = {
              single_logout = false;
              auto_provision = true;
              soft_auto_provision = true;
            };

            allow_user_to_change_display_name = false;
            lost_password_link = "disabled";
            oidc_login_provider_url = "https://${config.authelia.hostName}";
            oidc_login_client_id = "nextcloud";
            # oidc_login_client_secret = "insecure_secret"; # set in secret file
            oidc_login_auto_redirect = false;
            oidc_login_end_session_redirect = false;
            oidc_login_button_text = "Log in with Authelia";
            oidc_login_hide_password_form = false;
            oidc_login_use_id_token = true;
            oidc_login_attributes = {
              id = "preferred_username";
              name = "name";
              mail = "email";
              groups = "groups";
            };
            oidc_login_default_group = "oidc";
            oidc_login_use_external_storage = false;
            oidc_login_scope = "openid profile email groups";
            oidc_login_proxy_ldap = false;
            oidc_login_disable_registration = false; # different from doc, to enable auto creation of new users
            oidc_login_redir_fallback = false;
            oidc_login_tls_verify = false; # TODO set to true when using real certs
            oidc_create_groups = false;
            oidc_login_webdav_enabled = false;
            oidc_login_password_authentication = false;
            oidc_login_public_key_caching_time = 86400;
            oidc_login_min_time_between_jwks_requests = 10;
            oidc_login_well_known_caching_time = 86400;
            oidc_login_update_avatar = false;
            oidc_login_code_challenge_method = "S256";
          };
        # secret file currectly only used to provide:
        # - oidc_login_client_secret for authelia
        # - mail_smtppassword for mail
        secretFile = mkIf config.authelia.enable config.age.secrets.nextcloudSecretFile.path;
      };

      onlyoffice = mkIf config.onlyoffice.enable {
        enable = true;
        hostname = config.onlyoffice.hostName;
        jwtSecretFile = config.age.secrets.onlyofficeKey.path;
      };
    };
  };
}
