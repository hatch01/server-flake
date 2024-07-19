{
  config,
  hostName,
  lib,
  mkSecret,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  bridgeFolder = "/var/lib/mautrix-signal";

  toListIfExists = path:
    if (lib.pathExists path)
    then [path]
    else [];

  mautrixSignalConfig = ''
    homeserver:
      address: "https://matrix.example.com"
      domain: "example.com"
    signal:
      listen: ["127.0.0.1:29328"]
      path: "/path/to/signal-cli"
      user: "signal-user"
    bridge:
      permissions:
        "*": user
        "@pseudo:server_name": admin
  '';
in {
  options = {
    matrix = {
      signal = {
        enable = mkEnableOption "enable matrix";
      };
    };
  };

  config = mkIf config.matrix.signal.enable {
    age.secrets = mkSecret "matrix_shared_secret" {
      owner = "mautrix-signal";
    };

    services.mautrix-signal = {
      enable = true;
      # environmentFile =
      registerToSynapse = true;
      # serviceDependencies
      settings = {
        bridge = {
          permissions = {
            "*" = "relay";
            "${config.matrix.hostName}" = "eymeric";
            "@eymeric:onyx.ovh" = "admin";
          };
          login_shared_secret_map = {
            "onyx.ovh" = "YOUR_SHARED_SECRET_THAT_WILL_BE_REPLACED_BY_ENV_VAR";
          };
        };
        homeserver = {
          address = "http://localhost:${toString config.matrix.port}";
        };
      };
      environmentFile = config.age.secrets.matrix_shared_secret.path;
    };
  };
}
