{
  disko.devices = let
    rootDisk = "/dev/vda";
    dataDisk1 = "/dev/vdb";
    dataDisk2 = "/dev/vdc";
  in {
    disk = {
      main = {
        device = rootDisk;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "swap";
                randomEncryption = true;
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
                };
                mountpoint = "/partition-root";
              };
            };
          };
        };
      };
      data1 = {
        type = "disk";
        device = dataDisk1;
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };
      data2 = {
        type = "disk";
        device = dataDisk2;
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "storage";
              };
            };
          };
        };
      };
    };
    zpool = {
      storage = {
        type = "zpool";
        mode = "mirror";
        # rootFsOptions = {
        # compression = "zstd";
        # "com.sun:auto-snapshot" = "false";
        # };
        mountpoint = "/storage";
      };
    };
  };
}
