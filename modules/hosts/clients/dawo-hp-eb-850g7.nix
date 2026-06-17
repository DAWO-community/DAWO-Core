{
  config,
  ...
}:
{
  flake.modules.nixos."hosts/dawo-hp-eb-850g7" =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        # Boot
        boot-systemd
        boot-plymouth-bzk

        # Disko
        disko-single-nvme-luks

        # Hardware
        hardware-hp-elitebook-850-g7

        # Profiles
        profiles-dawo-generic

        # Userland
        maid-dawo-generic

      ];
      networking.hostName = "dawo-hp-eb-850g7";

    };
}
