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
            energy_phase = "auto";
            production = "false";
            kWh_precision = "3";
          };
          "0x70b3d52b600b8d61".friendly_name = "Frigo";
          "0xa4c13838417869a3".friendly_name = "temperature eymeric";
          "0x70b3d52b600bbd25".friendly_name = "Lave linge, four";
          "0x70b3d52b600b87f6".friendly_name = "four; micro-onde; grille pain";
          "0xa4c1383010c51a37".friendly_name = "temperature Kevin";
          "0x70b3d52b600b8a69".friendly_name = "PC Kevin";
          "0xa4c1387c77f5cec7".friendly_name = "temperature Salon";
          "0xa4c138c7433ae2c1".friendly_name = "temperature Salle de Bain";
          "0xa4c1380f61a7c337".friendly_name = "temperature Cuisine";
          "0x70b3d52b600bc013".friendly_name = "Serveur";
          "0xa4c138ee4f964b0c".friendly_name = "Chauffe eau";
          "0xa4c13825eae893f2".friendly_name = "PC Eymeric";
          "0xa4c1380d227318c3".friendly_name = "Chauffage Eymeric";
        };
      };
    };

    services.mosquitto = {
      enable = true;
      dataDir = "/storage/homeassistant/mosquitto";
    };
  };
}
