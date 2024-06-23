{
  disko.devices = let
    rootDisk = "/dev/sda";
    dataDisk1 = "/dev/sdb";
    dataDisk2 = "/dev/sdc";
  in {
    disk = {
      main = {
        device = rootDisk;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
              priority = 1; # Needs to be first partition
            };
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # override existing partition
                subvolumes = {
                  "/rootfs" = {
                    mountpoint = "/";
                  };
                  "/nix" = {
                    mountOptions = ["noatime"];
                    mountpoint = "/nix";
                  };
                  "/persistent" = {
                    # neededForBoot = true;
                    mountpoint = "/persistant";
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap = {
                      swapfile.size = "20M";
                      swapfile2.size = "20M";
                      swapfile2.path = "rel-path";
                    };
                  };
                };
                mountpoint = "/partition-root";
                swap = {
                  swapfile.size = "20M";
                  swapfile1.size = "20M";
                };
              };
            };
          };
        };
      };
    data1 = {
      type ="disk";
      device = dataDisk1;
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };
    data2 = {
      type ="disk";
      device = dataDisk2;
      content = {
        type = "gpt";
        partitions = {
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "zdata";
            };
          };
        };
      };
    };
    };
    zpool = {
      zdata = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          # compression = "zstd";
          # "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/data";

      };
    };
  };
}
