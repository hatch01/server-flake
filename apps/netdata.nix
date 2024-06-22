{
  lib,
  config,
  hostName,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    netdata = {
      enable = mkEnableOption "enable Netdata";
      hostName = mkOption {
        type = types.str;
        default = "netdata.${hostName}";
        description = "The hostname of the Netdata instance";
      };
      port = mkOption {
        type = types.int;
        default = 19999;
        description = "The port of the Netdata instance WARNING THIS HAS NO REAL EFFECT";
      };
    };
  };

  config = mkIf config.netdata.enable {
    services = {
      netdata = {
        enable = true;
        config = {
          global = {
            # uncomment to reduce memory to 32 MB
            #"page cache size" = 32;

            # update interval
            "update every" = 15;
          };
          ml = {
            "enabled" = "yes";
          };
        };
      };

      # enable nginx status page to get nginx stats
      nginx.virtualHosts = {
        "_" = {
          locations."/stub_status" = {
            extraConfig = ''
              stub_status on;
              access_log off;
              allow 127.0.0.1;
              deny all;'';
          };
        };
      };

      #setup postgresql netdata user to access postgresql stats
      postgresql = {
        enable = true;
        ensureUsers = [
          {name = "netdata";}
        ];
        initialScript =
          pkgs.writeText "grant-netdata"
          "GRANT pg_monitor TO netdata;";
      };
    };
  };
}
