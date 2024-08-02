{
  lib,
  config,
  hostName,
  mkSecret,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf optionals types;
in {
  options = {
    ddclient = {
      enable = mkEnableOption "enable ddclient";
    };
  };

  config = mkIf config.ddclient.enable {
    age.secrets = mkSecret "dyndns" {};

    services.ddclient = {
      enable = true;
      protocol = "dyndns2";
      use = "web, web=api.ipify.org";
      server = "www.ovh.com";
      username = "onyx.ovh-box";
      passwordFile = config.age.secrets.dyndns.path;
      domains = [
        config.adguard.hostName
        config.gitlab.hostName
        config.authelia.hostName
        config.nextcloud.hostName
        config.matrix.hostName
        config.homepage.hostName
        config.netdata.hostName
        config.nixCache.hostName
      ];
    };
  };
}
