{
  # auditd (BIO detection). MANDATORY-core tier - but a NO-OP on nixpkgs 26.05.
  # Norm: ANSSI R33 + BIO (non-repudiation). Origin: securix auditd.nix.
  #
  # auditctl 4.1.2-unstable + the NixOS audit module reject line 2 of the
  # generated rules file ('error in line 2', status 255), even with a single
  # rule. Module/version bug, not our rules. Kept OFF until upstream fixes it,
  # otherwise every `nixos-rebuild switch` fails. journald + chrony cover the
  # log/time base meanwhile.
  #
  # When the bug is gone, fill the mkIf body with:
  #   security.auditd.enable = true;
  #   security.audit.enable = true;
  #   security.audit.rules = [ "-a exit,always -F arch=b64 -S execve -k exec" ];
  flake.modules.nixos.hardening-audit =
    { config, lib, ... }:
    let
      cfg = config.dawo.audit;
    in
    {
      options.dawo.audit.enable = lib.mkEnableOption "auditd kernel audit (BIO) - currently a no-op, blocked on a 26.05 module bug";

      # Intentionally empty until the auditctl/module bug is fixed.
      config = lib.mkIf cfg.enable { };
    };
}
