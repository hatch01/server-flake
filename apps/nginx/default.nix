{
  config,
  lib,
  hostName,
  mkSecrets,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
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
          # enableACME = true;
          # extraConfig = builtins.readFile ./authelia-location.conf;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString config.homepage.port}";
              extraConfig = lib.strings.concatStringsSep "\n" [
                (builtins.readFile ./auth-proxy.conf)
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

        ${config.forgejo.hostName} = mkIf config.forgejo.enable {
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
          locations."/".proxyPass = "http://localhost:${toString config.forgejo.port}";
        };
        ${config.dendrite.hostName} = mkIf config.dendrite.enable {
          inherit (cfg) forceSSL sslCertificate sslCertificateKey;
          locations."/".proxyPass = "http://localhost:${toString config.dendrite.port}";
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
