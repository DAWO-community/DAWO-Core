{
  flake.modules.nixos.networking-client =
    { lib, ... }:
    {
      networking = {
        enableIPv6 = true;
        nftables.enable = true;
        useNetworkd = true;
        useDHCP = lib.mkDefault true;

        wireless.enable = true;

        networkmanager = {
          enable = true;
          dhcp = "internal";
          dns = "systemd-resolved";
          wifi = {
            backend = "wpa_supplicant";
            macAddress = "preserve";
            powersave = true;
            scanRandMacAddress = true;
          };
          ensureProfiles = {
            profiles = { };
          };
        };

        firewall = {
          enable = true;
          # Open ports in the firewall, as needed.
          allowedTCPPorts = [ ];
          allowedUDPPorts = [ ];
        };
      };
      systemd.services.NetworkManager-wait-online.enable = false;
      systemd.network.wait-online.enable = false;
      boot.initrd.systemd.network.wait-online.enable = false;
    };
}
