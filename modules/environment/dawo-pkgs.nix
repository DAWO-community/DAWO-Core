{
  flake.modules.nixos.environment-dawo-pkgs =
    { pkgs, inputs, ... }:
    {
      imports = [
        # Import agenix NixOS module
        inputs.agenix.nixosModules.default
      ];
      # Universal baseline tools only. Applications live in opt-in dawo.apps.*
      # blocks (apps-sets); the shell and browser in programs-zsh/programs-firefox;
      # vendor apps (microsoft-edge, teams-for-linux) in the org overlay. vlc and
      # freerdp stay in the base: a light media player and the RDP client for VDI.
      environment.systemPackages =
        with pkgs;
        [
          age
          dmidecode
          ethtool
          exfat
          exfatprogs
          fastfetch
          freerdp
          fzf
          htop
          libva-utils
          lm_sensors
          lsd
          lshw
          nix-search-cli
          pciutils
          resources
          solaar
          usbutils
          vlc
        ]
        ++ [
          inputs.agenix.packages."${stdenv.hostPlatform.system}".default
        ];
    };
}
