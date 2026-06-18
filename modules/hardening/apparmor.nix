{
  # AppArmor MAC. OPT-IN tier (default off). Can hit app sandboxes (Chromium
  # freeze seen) -> enable on a canary with proper profiles first.
  # Norm: ANSSI R37/R45-49 (MAC) + BIO/STIG. See architecture.md "Key Design Decisions".
  flake.modules.nixos.hardening-apparmor =
    { config, lib, ... }:
    let
      cfg = config.dawo.apparmor;
    in
    {
      options.dawo.apparmor.enable = lib.mkEnableOption "AppArmor mandatory access control (opt-in)";

      config = lib.mkIf cfg.enable {
        security.apparmor.enable = true;
      };
    };
}
