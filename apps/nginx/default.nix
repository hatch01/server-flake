{
  config,
  lib,
  hostName,
  mkSecrets,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = {
    age.secrets = let
      cfg = {
        owner = "nginx";
        group = "nginx";
      };
    in
      mkSecrets {
        selfSignedCert = cfg;
        selfSignedCertKey = cfg;
      };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "eymeric.monitoring@free.fr";
      };
    };

    # when we have dns
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      additionalModules = with pkgs.nginxModules; [modsecurity];
      proxyCachePath = {
        "" = {
          enable = true;
          keysZoneName = "cache";
        };
      };

      virtualHosts = let
        cfg = {
          forceSSL = true;
          useACMEHost = hostName;
          enableACME = true;
          extraConfig = "proxy_cache cache;\n";
        };
      in {
        "${hostName}" = let
          baseUrl = "https://${config.matrix.hostName}";
          clientConfig."m.homeserver".base_url = baseUrl;
          serverConfig."m.server" = "${config.matrix.hostName}:443";
          mkWellKnown = data: ''
            default_type application/json;
            add_header Access-Control-Allow-Origin *;
            return 200 '${builtins.toJSON data}';
          '';
        in {
          inherit (cfg) forceSSL enableACME;
          locations = {
            "/" = mkIf config.homepage.enable {
              proxyPass = "http://localhost:${toString config.homepage.port}";
              extraConfig = lib.strings.concatStringsSep "\n" [
                (builtins.readFile ./auth-authrequest.conf)
              ];
            };
            # Corresponds to https://www.authelia.com/integration/proxies/nginx/#authelia-locationconf
            "/internal/authelia/authz" = {
              proxyPass = "http://localhost:${toString config.authelia.port}/api/authz/auth-request";
              extraConfig = builtins.readFile ./auth-location.conf;
            };

            "= /.well-known/matrix/server".extraConfig = mkIf config.matrix.enable (mkWellKnown serverConfig);
            "= /.well-known/matrix/client".extraConfig = mkIf config.matrix.enable (mkWellKnown clientConfig);
          };
        };

        ${config.netdata.hostName} = mkIf config.netdata.enable {
          inherit (cfg) forceSSL enableACME;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString config.netdata.port}";
              extraConfig = lib.strings.concatStringsSep "\n" [
                (builtins.readFile ./auth-authrequest.conf)
              ];
            };
            # Corresponds to https://www.authelia.com/integration/proxies/nginx/#authelia-locationconf
            "/internal/authelia/authz" = {
              proxyPass = "http://localhost:${toString config.authelia.port}/api/authz/auth-request";
              extraConfig = builtins.readFile ./auth-location.conf;
            };
          };
        };

        ${config.adguard.hostName} = mkIf config.adguard.enable {
          inherit (cfg) forceSSL enableACME;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString config.adguard.port}";
              extraConfig = lib.strings.concatStringsSep "\n" [
                (builtins.readFile ./auth-authrequest.conf)
              ];
            };
            # Corresponds to https://www.authelia.com/integration/proxies/nginx/#authelia-locationconf
            "/internal/authelia/authz" = {
              proxyPass = "http://localhost:${toString config.authelia.port}/api/authz/auth-request";
              extraConfig = builtins.readFile ./auth-location.conf;
            };
          };
        };

        # TODO create a simplified method to define those
        ${config.nextcloud.hostName} = mkIf config.nextcloud.enable {
          inherit (cfg) forceSSL extraConfig enableACME;
        };

        ${config.onlyoffice.hostName} = mkIf config.onlyoffice.enable {
          inherit (cfg) forceSSL extraConfig enableACME;
        };

        ${config.gitlab.hostName} = mkIf config.gitlab.enable {
          inherit (cfg) forceSSL extraConfig enableACME;
          locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };

        ${config.matrix.hostName} = let
          clientConfig."m.homeserver".base_url = "https://${config.matrix.hostName}";
        in
          mkIf config.matrix.enable {
            inherit (cfg) forceSSL extraConfig enableACME;
            serverAliases = [config.matrix.hostName];
            root = mkIf config.matrix.enableElement (pkgs.element-web.override {
              conf = {
                default_server_config = clientConfig; # see `clientConfig` from the snippet above.
              };
            });
            locations = {
              "/".extraConfig = mkIf (! config.matrix.enableElement) ''
                return 404;
              '';
              # Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
              # *must not* be used here.
              "/_matrix".proxyPass = "http://[::1]:${toString config.matrix.port}";
              # Forward requests for e.g. SSO and password-resets.
              "/_synapse/client".proxyPass = "http://[::1]:${toString config.matrix.port}";
            };
          };
        ${config.nixCache.hostName} = mkIf config.nixCache.enable {
          inherit (cfg) forceSSL extraConfig enableACME;
          locations."/".proxyPass = "http://localhost:${toString config.nixCache.port}";
        };

        ${config.homeassistant.hostName} = mkIf config.homeassistant.enable {
          inherit (cfg) forceSSL  enableACME;
          extraConfig = ''
            proxy_buffering off;
          '';
          locations."/" = {
            proxyPass = "http://localhost:${toString config.homeassistant.port}";
            proxyWebsockets = true;
          };
        };

        ${config.authelia.hostName} = mkIf config.authelia.enable {
          inherit (cfg) forceSSL extraConfig enableACME;
          locations = let
            authUrl = "http://localhost:${toString config.authelia.port}";
          in {
            "/".proxyPass = authUrl;
            "/api/verify".proxyPass = authUrl;
            "/api/authz".proxyPass = authUrl;
          };
        };
      };
    };
    networking.firewall.allowedTCPPorts = [80 443];
  };
}
