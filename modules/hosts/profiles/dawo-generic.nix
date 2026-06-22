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

        # Hardening (mandatory-core tier; opt-in blocks enabled per workplace)
        profiles-dawo-core

        # Desktop (DE-agnostic: blocks are gated, a host enables exactly one of
        # dawo.desktop.plasma.enable / dawo.desktop.gnome.enable; desktop-select
        # asserts the choice)
        desktop-plasma
        desktop-gnome
        desktop-sddm-bzk
        desktop-select

        # Environment
        environment-dawo-vars
        environment-dawo-pkgs
        environment-fonts
        environment-dawo-version

        # Apps - opt-in sets (off by default; a host/overlay enables what it wants)
        apps-sets

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
