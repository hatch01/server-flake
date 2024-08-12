{
  lib,
  config,
  mkSecret,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
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
      usev4 = "web, web=api.ipify.org";
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
