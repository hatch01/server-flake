{lib, ...}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      #for only office
      "corefonts"
    ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];
}
