{
  config,
  ...
}:
{
  # OPT-IN (hardened) tier aggregate. Importing this only DECLARES the opt-in
  # blocks (so `dawo.<block>.enable` exists); they stay default OFF. A workplace
  # imports this and flips the ones it wants, e.g.:
  #   dawo.apparmor.enable = true;
  # Risky/policy blocks belong here, not in profiles-dawo-core.
  flake.modules.nixos.profiles-dawo-hardened =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        hardening-apparmor
        hardening-gnome
        # next batch: hardening-pam-u2f, hardening-pam-oath, hardening-egress-deny
      ];
    };
}
