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
    homepage.enable = mkEnableOption "Enable homepage";
    homepage.hostName = mkOption {
      type = types.str;
      default = hostName;
      description = "The hostname of the homepage";
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
                  href = "http://${config.nextcloud.hostName}";
                  siteMonitor = "http://${config.nextcloud.hostName}";
                  widget = {
                    type = "nextcloud";
                    url = "http://${config.nextcloud.hostName}";
                    username = "root";
                    password = "{{HOMEPAGE_VAR_NEXTCLOUD_PASS}}";
                  };
                };
              }
              {
                "forgejo" = {
                  icon = "forgejo.png";
                  description = "forgejo c'est vraiment cool";
                  href = "http://${config.forgejo.hostName}";
                  siteMonitor = "http://${config.forgejo.hostName}";
                  widget = {
                    type = "gitea";
                    url = "http://${config.forgejo.hostName}";
                    key = "{{HOMEPAGE_VAR_FORGEJO_KEY}}";
                  };
                };
              }
              {
                "Dendrite" = {
                  icon = "matrix.png";
                  description = "Dendrite c'est vraiment cool";
                  href = "http://${config.dendrite.hostName}";
                  siteMonitor = "http://${config.dendrite.hostName}";
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

      nginx = {
        enable = true;
        recommendedProxySettings = true;
        virtualHosts = {
          "${config.homepage.hostName}" = {
            locations."/".proxyPass = "http://localhost:8082";
          };
        };
      };
    };
    networking.firewall.allowedTCPPorts = [80 443];
  };
}