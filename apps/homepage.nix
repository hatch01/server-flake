{
  pkgs,
  config,
  hostName,
  mkSecret,
  ...
}: let
  homepageHost = hostName;
in {
  age.secrets = mkSecret "nextcloudAdmin" {
    # owner = "homepage-dashboard";
    # group = "homepage-dashboard";
  };

  services = {
    homepage-dashboard = {
      enable = true;
      openFirewall = false;
      bookmarks = [];
      services = [
        {
          "Group 1" = [
            {
              "Nextcloud" = let
                nextcloudUrl = "http://nextcloud.${hostName}/";
              in {
                icon = "nextcloud.png";
                description = "Nextcloud c'est vraiment cool";
                href = nextcloudUrl;
                ping = nextcloudUrl;
                widget = {
                  type = "nextcloud";
                  url = nextcloudUrl;
                  username = "root";
                  # password = config.age.secrets.nextcloudAdmin;
                  password = "...";
                };
              };
            }
            {
              "Gitlab" = {
                icon = "gitlab.png";
                description = "Gitlab c'est vraiment cool";
                href = "http://gitlab.${hostName}/";
                ping = "http://gitlab.${hostName}/";
              };
            }
            {
              "Dendrite" = {
                icon = "matrix.png";
                description = "Dendrite c'est vraiment cool";
                href = "http://dendrite.${hostName}/";
                ping = "http://dendrite.${hostName}/";
              };
            }
          ];
        }
      ];
      settings = {
        title = "Onyx Homepage";
        background = "https://images.unsplash.com/photo-1502790671504-542ad42d5189?auto=format&fit=crop&w=2560&q=80";
        headerStyle = "clean";
        language = "fr";
        quicklaunch = {
          prompt = "duckduckgo";
          showSearchSuggestions = true;
          searchDescriptions = true;
        };
      };
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
        "${homepageHost}" = {
          locations."/".proxyPass = "http://localhost:8082";
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [80 443];
}
