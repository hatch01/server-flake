# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  hostName,
  lib,
  ...
} @ args: let
  secretsPath = ./secrets;
  mkSecrets = builtins.mapAttrs (name: value: value // {file = "${secretsPath}/${name}.age";});
  mkSecret = name: other: mkSecrets {${name} = other;};

  fudgeMyShitIn = builtins.map (file: import file (args // {inherit mkSecret mkSecrets fudgeMyShitIn;}));
in {
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./unfree.nix
      ./impermanence.nix
    ]
    ++ fudgeMyShitIn [
      apps/gitlab
      apps/homepage.nix
      apps/nextcloud.nix
      apps/authelia.nix
      apps/nginx
      apps/netdata.nix
      apps/nixCache.nix
      apps/adguard.nix
      apps/fail2ban.nix
      apps/matrix
    ];

  nextcloud.enable = true;
  onlyoffice.enable = true;
  homepage.enable = true;
  authelia.enable = true;
  gitlab.enable = true;
  netdata.enable = true;
  nixCache.enable = true;
  adguard.enable = true;
  fail2ban.enable = true;
  matrix.enable = true;
  matrix.enableElement = true;

  adguard.hostName = "dns.${hostName}";
  gitlab.hostName = "forge.${hostName}";

  security.pki.certificates = [
    ''      -----BEGIN CERTIFICATE-----
      MIIDxTCCAq2gAwIBAgIUP6Jh5XBWvz34WVfJP5mXwxvVgWkwDQYJKoZIhvcNAQEL
      BQAwUzELMAkGA1UEBhMCRlIxDjAMBgNVBAgMBVJob25lMQ0wCwYDVQQHDARMeW9u
      MRIwEAYDVQQKDAlPbnl4IGNvcnAxETAPBgNVBAMMCG9ueXgub3ZoMB4XDTI0MDYy
      MjEyNTYyM1oXDTI1MDYyMjEyNTYyM1owUzELMAkGA1UEBhMCRlIxDjAMBgNVBAgM
      BVJob25lMQ0wCwYDVQQHDARMeW9uMRIwEAYDVQQKDAlPbnl4IGNvcnAxETAPBgNV
      BAMMCG9ueXgub3ZoMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2jIx
      yXkK+i3m9fH3aG47lmlLQSakqpgCiJjplUtnpTKnyJFSYVCSXh05KkeXHWbHIuB0
      LmD781x3g43ozL79szM/twG5EoJRJlf6f1afolx+eAuFeFgyhbzLOorw8quHF99e
      L9uCx439/+F74DV9saRsXfifJwm+lfEZFhL8asaw996RfcMXLNg9P/ukjVv0aInh
      gSHCqfqr1VqELMDxCKzCzvAfksGCnG5NrtmhMDPtPjTEw9MDfdscrrru2lpB1D0W
      gLBl4AISCcPFV5MNpIJoSRw2sMxE66nicjapNTKIsaUcLYylGeMAXab0aOu3ewQU
      mITcf9PEB/Fgz+3XzwIDAQABo4GQMIGNMAsGA1UdDwQEAwIEMDATBgNVHSUEDDAK
      BggrBgEFBQcDATBKBgNVHREEQzBBgghvbnl4Lm92aIIRYXV0aGVsaWEub255eC5v
      dmiCEm5leHRjbG91ZC5vbnl4Lm92aIIOZm9yZ2Uub255eC5vdmgwHQYDVR0OBBYE
      FJir+L4iZyesGP7Hu4QAKtNjiBTbMA0GCSqGSIb3DQEBCwUAA4IBAQA7O6uEC3he
      CshWXIgQHiq+s2wUzxQWap6Eywd/UHhd3JqjGA9qpT7/soMzdBuo+aMwf3WwJwEE
      q0tLEwbIRv8Wf/VVdzXcu04KsNJOCG3F6sG3wI8V4n/X3aPPlkQWywI8QfNWTz3w
      QkFX2knMAcjRYgXdZg+GDNHD/dLYgbzlA2lxfGVU/2OCU4vl77du6HnTY894y3Pp
      6HkObM9pdvhcLNmWLy3iObGR6eBHbTGomToP/T6/ln9k64KCI7Ipj7nL09cTvonP
      A1wgZtcQstUMPKuvcVYPqFPay4KXpxGLbz7Jh+BWrZqghuQmpTpEr4rxrW/a/lfn
      etI/ted5AZ9f
      -----END CERTIFICATE-----''
  ];

  nixpkgs.overlays = [
    ((import ./overlays/default.nix) inputs)
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["@wheel"];
  };

  age = {
    identityPaths = ["/persistent/key"];

    secrets = mkSecrets {
      userPassword = {};
      rootPassword = {};
      githubToken = {};
      smtpPassword = {
        group = "smtp";
        mode = "440";
      };
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zfs
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.forceImportRoot = false;
  boot.zfs.devNodes = "/dev/disk/by-partuuid"; # TODO only needed in VMs

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = false;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking = {
    domain = hostName;
    networkmanager.enable = true;
    hostId = "271e1c23";
    hosts = {
      "127.0.0.1" = [
        "${hostName}"
        "nextcloud.${hostName}"
        "forge.${hostName}"
        "authelia.${hostName}"
        "matrix.${hostName}"
        "dns.${hostName}"
      ];
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_FR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    mutableUsers = false;
    users = {
      root = {
        hashedPasswordFile = config.age.secrets.rootPassword.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8szPPvvc4T9fsIR876a51XTWqSjtLZaYNmH++zQzNs eymericdechelette@gmail.com"
        ];
      };
      eymeric = {
        isNormalUser = true;
        description = "eymeric";
        extraGroups = ["networkmanager" "wheel"];
        hashedPasswordFile = config.age.secrets.userPassword.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8szPPvvc4T9fsIR876a51XTWqSjtLZaYNmH++zQzNs eymericdechelette@gmail.com"
        ];
      };
    };
    groups.smtp = {};
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    git
    inputs.agenix.packages.${system}.default
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    #docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  nix.optimise.automatic = true;
  nix.optimise.dates = ["03:45"]; # Optional; allows customizing optimisation schedule

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.extraOptions = ''
    !include ${config.age.secrets.githubToken.path}
  '';
}
