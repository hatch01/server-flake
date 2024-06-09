{
  pkgs,
  config,
  hostName,
  ...
}: let
  homepageHost = "${hostName}";
in {
  services = {
    homepage-dashboard = {
      enable = true;
      
    };
  };
}
