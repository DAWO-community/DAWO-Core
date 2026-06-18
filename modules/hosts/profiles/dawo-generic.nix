{
  config,
  ...
}:
{
  flake.modules.nixos.profiles-dawo-generic =
    { lib, ... }:
    {
      # Auto-update on by default; a workplace overrides repoUrl to its overlay.
      dawo.autoUpdate.enable = lib.mkDefault true;

      imports = with config.flake.modules.nixos; [

        # Desktop
        desktop-plasma
        desktop-sddm-bzk

        # Environment
        environment-dawo-vars
        environment-dawo-pkgs
        environment-fonts

        # Localization
        localization-nl_nl

        # Networking
        networking-client

        # NixOS
        nixos-nix-settings
        nixos-system

        # Programs
        programs-git
        programs-zsh
        programs-chromium
        programs-firefox

        # Services
        services-auto-update
        services-flatpak

        # Users
        users-basics
        users-dawo
        users-deploy
      ];
    };
}
