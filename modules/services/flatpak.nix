{
  flake.modules.nixos.services-flatpak =
    { inputs, ... }:
    {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];

      services.flatpak = {
        enable = true;
        uninstallUnmanaged = true;
        update.onActivation = true;
        update.auto = {
          enable = true;
          onCalendar = "weekly"; # Default value
        };
        overrides = {
          global = {
            # Force Wayland by default
            Context.sockets = [
              "wayland"
              "!x11"
              "!fallback-x11"
            ];
          };
        };
        # Prefer packages from NixOS, only use this when no other alternative is available
        packages = [
        ];
      };
    };
}
