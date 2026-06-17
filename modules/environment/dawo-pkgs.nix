{
  flake.modules.nixos.environment-dawo-pkgs =
    { pkgs, inputs, ... }:
    {
      imports = [
        # Import agenix NixOS module
        inputs.agenix.nixosModules.default
      ];
      environment.systemPackages =
        with pkgs;
        [
          age
          collabora-desktop
          ctags
          direnv
          dmidecode
          element-desktop
          ethtool
          exfat
          exfatprogs
          fastfetch
          freerdp
          fzf
          gcc
          gimp-with-plugins
          htop
          inkscape
          krita
          libva-utils
          lm_sensors
          lsd
          lshw
          nil
          nix-search-cli
          nixd
          nixfmt
          penpot-desktop
          pciutils
          resources
          solaar
          teams-for-linux
          thunderbird
          usbutils
          uv
          vlc
          vscodium
          zsh
          microsoft-edge
          firefox
        ]
        ++ [
          inputs.agenix.packages."${stdenv.hostPlatform.system}".default
        ];
    };
}
