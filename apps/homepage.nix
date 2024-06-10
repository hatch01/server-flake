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
                  href = config.nextcloud.hostName;
                  siteMonitor = config.nextcloud.hostName;
                  widget = {
                    type = "nextcloud";
                    url = config.nextcloud.hostName;
                    username = "root";
                    password = "{{HOMEPAGE_VAR_NEXTCLOUD_PASS}}";
                  };
                };
              }
              {
                "Gitlab" = {
                  icon = "gitlab.png";
                  description = "Gitlab c'est vraiment cool";
                  href = "http://gitlab.${hostName}/";
                  siteMonitor = "http://gitlab.${hostName}/";
                };
              }
              {
                "Dendrite" = {
                  icon = "matrix.png";
                  description = "Dendrite c'est vraiment cool";
                  href = config.dendrite.hostName;
                  siteMonitor = config.dendrite.hostName;
                };
              }
            ];
          }
        ];

        widgets = [];
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
