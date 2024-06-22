{
  config,
  hostName,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    gitlab = {
      enable = mkEnableOption "enable Gitlab";
      hostName = mkOption {
        type = types.str;
        default = "forge.${hostName}";
        description = "The hostname of the Gitlab instance";
      };
    };
  };

  config = mkIf config.gitlab.enable {
    age = {
      identityPaths = ["/etc/age/key"];
      secrets = {
        databasePasswordFile = {
          file = ../secrets/gitlab/databasePasswordFile.age;
          owner = "gitlab";
        };
        initialRootPasswordFile = {
          file = ../secrets/gitlab/initialRootPasswordFile.age;
          owner = "gitlab";
        };
        secretFile = {
          file = ../secrets/gitlab/secretFile.age;
          owner = "gitlab";
        };
        otpFile = {
          file = ../secrets/gitlab/otpFile.age;
          owner = "gitlab";
        };
        dbFile = {
          file = ../secrets/gitlab/dbFile.age;
          owner = "gitlab";
        };
        jwsFile = {
          file = ../secrets/gitlab/jwsFile.age;
          owner = "gitlab";
        };
      };
    };

    services.gitlab = {
      enable = true;
      host = config.gitlab.hostName;
      databasePasswordFile = config.age.secrets.databasePasswordFile.path;
      initialRootPasswordFile = config.age.secrets.initialRootPasswordFile.path;
      secrets = {
        secretFile = config.age.secrets.secretFile.path;
        otpFile = config.age.secrets.otpFile.path;
        dbFile = config.age.secrets.dbFile.path;
        jwsFile = config.age.secrets.jwsFile.path;
      };
    };
  };
}
