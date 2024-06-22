{
  config,
  hostName,
  mkSecret,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    homepage = {
      enable = mkEnableOption "Enable homepage";
      hostName = mkOption {
        type = types.str;
        default = hostName;
        description = "The hostname of the homepage";
      };
      port = mkOption {
        type = types.int;
        default = 8082;
        description = "The port of the homepage";
      };
    };
  };

  config = {
    age.secrets = mkSecret "homepage" {
      owner = "root";
      group = "users";
      mode = "400";
    };

    services = mkIf config.homepage.enable {
      homepage-dashboard = {
        enable = true;
        openFirewall = false;
        environmentFile = config.age.secrets.homepage.path;
        bookmarks = [];
        listenPort = config.homepage.port;
        settings = {
          title = "Onyx Homepage";
          background = "https://images.unsplash.com/photo-1485431142439-206ba3a9383e?q=80&w=1966&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
          headerStyle = "clean";
          language = "fr";
          theme = "light";
          quicklaunch = {
            prompt = "duckduckgo";
            showSearchSuggestions = true;
            searchDescriptions = true;
          };
        };
        services = [
          {
            "Group 1" = [
              {
                "Nextcloud" = {
                  icon = "nextcloud.png";
                  description = "Nextcloud c'est vraiment cool";
                  href = "https://${config.nextcloud.hostName}";
                  siteMonitor = "https://${config.nextcloud.hostName}";
                  widget = {
                    type = "nextcloud";
                    url = "https://${config.nextcloud.hostName}";
                    username = "root";
                    password = "{{HOMEPAGE_VAR_NEXTCLOUD_PASS}}";
                  };
                };
              }
              {
                "Gitlab" = {
                  icon = "gitlab.png";
                  description = "Gitlab c'est vraiment cool";
                  href = "https://${config.gitlab.hostName}/";
                  siteMonitor = "https://${config.gitlab.hostName}/";
                };
              }
              {
                "Dendrite" = {
                  icon = "matrix.png";
                  description = "Dendrite c'est vraiment cool";
                  href = "https://${config.dendrite.hostName}";
                  siteMonitor = "https://${config.dendrite.hostName}";
                  # TODO complete with a custom api status widget
                  # widget = {
                  # }
                };
              }
            ];
          }
        ];

        widgets = [
          {
            datetime = {
              text_size = "4x1";
              format = {
                timeStyle = "medium";
                dateStyle = "full";
              };
            };
          }
          {
            logo.icon = "https://raw.githubusercontent.com/onyx-lyon1/onyx/main/apps/onyx/assets/icon_transparent.png";
          }
          {
            openmeteo = {
              label = "Lyon";
              latitute = 45.7779057;
              longitude = 4.8817357;
              timezone = "Europe/Paris";
              units = "metric";
              cache = 5;
              format.maximumFractionDigits = 2;
            };
          }
          {
            resources = {
              cpu = true;
              memory = true;
              disk = ["/dev/disk/by-partlabel/disk-main-root"];
              cputemp = true;
              tempmin = 0;
              tempmax = 100;
              uptime = true;
              units = "metric";
              refresh = 300;
              diskUnit = "bytes";
            };
          }
        ];
        kubernetes = [];
        docker = [];
        customJS = "";
        customCSS = "";
      };
    };
  };
}
