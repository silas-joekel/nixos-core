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
              # Wenn password ein String ist, nutze ihn als Pfad. 
 	      # Wenn password null ist, fragt NixOS beim Booten interaktiv.
   	      passwordFile = if (builtins.isString password) then password else null;
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
