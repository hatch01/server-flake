{
  config,
  hostName,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  imports = [
    ./zigbee2mqtt.nix
  ];

  options = {
    homeassistant = {
      enable = mkEnableOption "Home Assistant";
      hostName = mkOption {
        type = types.str;
        default = "home.${hostName}";
      };
      port = mkOption {
        type = types.int;
        default = 8123;
      };
    };
  };

  config = mkIf config.homeassistant.enable {
    zigbee2mqtt.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.homeassistant = {
        volumes = ["/storage/homeassistant/:/config"];
        environment.TZ = "Europe/Paris";
        image = "ghcr.io/home-assistant/home-assistant:stable";
        extraOptions = [
          "--network=host"
        ];
      };
    };
  };
}
