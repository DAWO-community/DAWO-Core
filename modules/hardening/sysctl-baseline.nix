{
  # System-level hardening (BIO/NCSC, low risk): strict sudo, temp-dir mount
  # options, login warning banner. MANDATORY-core tier.
  # Norm: ANSSI R9/R11/R12/R14 + CIS-DIL -> BIO. Origin: securix
  # anssi/kernel-options + filesystems. See architecture.md "Key Design Decisions".
  #
  # The sysctls moved to the register (hardening/rules/baseline-kernel.nix),
  # grouped by purpose, so a deployment can turn one group off by name. What is
  # left here is not a rule yet.
  flake.modules.nixos.hardening-sysctl-baseline =
    { config, lib, ... }:
    let
      cfg = config.dawo.sysctlBaseline;
    in
    {
      options.dawo.sysctlBaseline.enable = lib.mkEnableOption "strict sudo, temp-dir mount options and login banner (BIO/NCSC)";

      config = lib.mkIf cfg.enable {
        security.sudo.execWheelOnly = lib.mkForce true;

        boot.tmp.useTmpfs = true;
        fileSystems."/var/tmp" = {
          device = "/var/tmp";
          fsType = "none";
          options = [
            "bind"
            "nosuid"
            "nodev"
            "noexec"
          ];
        };

        environment.etc."issue".text = ''
          Geautoriseerd gebruik uitsluitend. Activiteit kan worden gelogd/gecontroleerd.
          Authorized use only. Activity may be logged and monitored.
        '';
        environment.etc."issue.net".text = ''
          Geautoriseerd gebruik uitsluitend. Activiteit kan worden gelogd/gecontroleerd.
          Authorized use only. Activity may be logged and monitored.
        '';
      };
    };
}
