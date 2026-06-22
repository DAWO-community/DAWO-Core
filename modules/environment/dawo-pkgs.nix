{
  flake.modules.nixos.environment-dawo-pkgs =
    { pkgs, inputs, ... }:
    {
      imports = [
        # Import agenix NixOS module
        inputs.agenix.nixosModules.default
      ];
      # Lean baseline for an end-user (office/VDI) laptop. Applications live in
      # opt-in dawo.apps.* blocks; shell/browser in programs-zsh/programs-firefox;
      # hardware/CLI diagnostics in the opt-in dawo.tools.diagnostics block (ops);
      # vendor apps in the org overlay. Kept here: the RDP client (VDI), exFAT
      # support (USB sticks), Logitech peripherals, a GUI task monitor, and
      # fastfetch (small, used by dawo-proof).
      environment.systemPackages =
        with pkgs;
        [
          exfat
          exfatprogs
          fastfetch
          freerdp
          resources
          solaar
        ]
        ++ [
          inputs.agenix.packages."${stdenv.hostPlatform.system}".default
        ];
    };
}
