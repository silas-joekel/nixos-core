# Diese Datei erwartet 'device' (z.B. /dev/nvme0n1) 
# und 'password' (das eingegebene Passwort) als Argumente.
{ device, password, ... }: {
  disko.devices = {
    disk.main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # 1. Boot-Partition (EFI)
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          # 2. Verschlüsselte Partition (LUKS)
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              # Nutzt das vom Script übergebene Passwort
              passwordFile = password; 
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Formatierung erzwingen
                subvolumes = {
                  "/root" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
                };
              };
            };
          };
        };
      };
    };
  };
}
