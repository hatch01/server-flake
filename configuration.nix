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
      ./modules
    ]
    ++ fudgeMyShitIn [
      apps/postgres.nix
      apps/gitlab
      apps/homepage.nix
      apps/nextcloud.nix
      apps/authelia.nix
      apps/nginx
      apps/netdata.nix
      apps/nixCache.nix
      apps/adguard.nix
      apps/fail2ban.nix
      apps/ddclient.nix
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
  ddclient.enable = true;

  adguard.hostName = "dns.${hostName}";
  gitlab.hostName = "forge.${hostName}";

  # networking.interfaces."eno1".wakeOnLan.policy =
  networking.interfaces."eno1".wakeOnLan.enable = true;
  boot.loader.timeout = 1;

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

  services.fwupd.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zfs
  boot.supportedFilesystems = ["zfs"];
  boot.zfs.forceImportRoot = false;
  systemd.services.zfs-mount.enable = false;
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
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8szPPvvc4T9fsIR876a51XTWqSjtLZaYNmH++zQzNs eymericdechelette@gmail.com"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCt8P+j17S6BHXZSWODBf9dOXuuj5bIdAaMyiyPv4YeU3SXlKpjczZIu4Rw15CUigDEGI8becAFfTRWrqF+/eoh//YId0uwrPDsThjNFbIFQdEp9C9FrM1tX8iB1sd37opPi/hu+WhDwS629tcmPvrzJ63VrXk0XEclS1U4f4Hu5k3kR98SYA/qm0cXf1Ioa85znPrQN6qWjQAzVyVRP2G4sK1koGM29a35t852L1zfoRojpJmW89maMekLMQrXjy9ZxThvW5rDpWDQljat6Bwq5DEEPTL+/8hwajRPiuRrNsFrS7xkCjKFkzxSHWkBjokTlpZUf9a0kAo5KTNiRwRUubTmO1x0602dUhPB0ZsbTOo+KHm8yFfSE0FtVefi4tfA3VBdnh9I7ooM3wIIPCYR9Pf7tQMHBaNQsTya+CqVCJeNeteVrPY/VdcckWg0QV+NLMyc2mEFooExD98VOsH6hUR4bQxi7GXJ0FARvWvhcNnSd80k7T/EPpDLJS+EGKE= flashonfire@Guillaume-Arch"
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
    #docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev
    btop
    killall
  ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
  };

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
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
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
