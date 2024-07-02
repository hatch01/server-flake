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
      # defaults = {
      #   email = "";
      # };
      # certs = {
      # extraDomainNames = [
      #   "${config.services.nextcloud.hostName}"
      #   "${config.homepage.hostName}"
      # ];
      # };
    };

    # when we have dns
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      additionalModules = with pkgs.nginxModules; [modsecurity];
      virtualHosts = let
        cfg = {
          forceSSL = true;
          sslCertificate = config.age.secrets.selfSignedCert.path;
          sslCertificateKey = config.age.secrets.selfSignedCertKey.path;
          useACMEHost = hostName;
        };
      in {
        "${hostName}" = mkIf config.homepage.enable {
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
          locations = {
            "/" = {
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
          };
        };

        ${config.netdata.hostName} = mkIf config.netdata.enable {
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
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
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
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
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
        };

        ${config.gitlab.hostName} = mkIf config.gitlab.enable {
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
          locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
        };
        ${config.dendrite.hostName} = mkIf config.dendrite.enable {
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
          locations."/".proxyPass = "http://localhost:${toString config.dendrite.port}";
        };
        ${config.nixCache.hostName} = mkIf config.nixCache.enable {
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
          locations."/".proxyPass = "http://localhost:${toString config.nixCache.port}";
        };

        ${config.authelia.hostName} = mkIf config.authelia.enable {
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
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
