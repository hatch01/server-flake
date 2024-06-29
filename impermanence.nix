{...}: {
  environment.persistence."/persistent" = {
    enable = true;
    directories = [
      {
        directory = "/root/.ssh";
        mode = "0700";
      }
      "/var/lib/systemd/coredump"
      "/etc/nixos"
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
      }
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
    users.eymeric = {
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    };
  };
}
