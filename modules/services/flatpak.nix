{
  # Flatpak, for the applications that exist nowhere else. Off the beaten path
  # by design: everything that can come from nixpkgs comes from nixpkgs, because
  # that is what flake.lock covers.
  #
  # The block used to be unconditional, and it updated itself weekly and on every
  # activation. That is a second software supply chain on a device whose whole
  # argument rests on pinning, so both are now decisions a deployment makes
  # rather than things it inherits.
  flake.modules.nixos.services-flatpak =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      cfg = config.dawo.flatpak;
    in
    {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];

      options.dawo.flatpak = {
        enable = lib.mkEnableOption "Flatpak, for applications that are not in nixpkgs" // {
          default = true;
        };

        autoUpdate = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Let Flatpak update its own applications, weekly and on every
            activation.

            Off by default. What arrives this way is not in `flake.lock`, is not
            reviewed, and does not roll back with the generation, so a
            deployment that turns it on is choosing a second update path
            alongside comin. A deployment that ships Flatpak applications
            probably wants exactly that; one that ships none gains nothing.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        services.flatpak = {
          enable = true;
          uninstallUnmanaged = true;
          update.onActivation = cfg.autoUpdate;
          update.auto = {
            enable = cfg.autoUpdate;
            onCalendar = "weekly";
          };
          overrides = {
            global = {
              # Wayland only. An X11 socket lets an application read every other
              # window's input, which takes the sandbox apart from the inside.
              Context.sockets = [
                "wayland"
                "!x11"
                "!fallback-x11"
              ];
            };
          };
          # Prefer packages from NixOS; this is for what has no other source.
          packages = [
          ];
        };
      };
    };
}
