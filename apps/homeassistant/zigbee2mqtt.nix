{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    zigbee2mqtt = {
      enable = mkEnableOption "enable zigbee2mqtt";
      port = mkOption {
        type = types.int;
        default = 8080;
        description = "The port on which zigbee2mqtt will listen";
      };
    };
  };

  config = mkIf config.zigbee2mqtt.enable {
    services.zigbee2mqtt = {
      enable = true;
      dataDir = "/storage/homeassistant/zigbee2mqtt";
      settings = {
        homeassistant = true;
        permit_join = true;
        mqtt = {
          base_topic = "zigbee2mqtt";
          server = "mqtt://localhost";
        };
        serial = {
          port = "/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20240220202746-if00";
          adapter = "ember";
          baudrate = 230400;
        };
        frontend = {
          port = config.zigbee2mqtt.port;
        };
        devices = {
          "0x00158d0005d263a7" = {
            friendly_name = "ZLinky";
            linky_mode = "standard";
            tarif = "Standard - Heure Pleine Heure Creuse";
            kWh_precision = "";
          };
        };
      };
    };

    services.mosquitto = {
      enable = true;
      dataDir = "/storage/homeassistant/mosquitto";
    };
  };
}
