{
  # SSH (CIS/NCSC). MANDATORY-core tier: sshd runs on every device.
  #
  # The floor itself - no root login, keys only, the crypto set - lives in the
  # register (hardening/rules/baseline-ssh.nix), one rule each, so a deployment
  # can turn one off by name instead of forking this block. What stays here is
  # what is not a control: that sshd runs, the banner, and the attempt limit a
  # host may tune.
  flake.modules.nixos.hardening-ssh =
    { config, lib, ... }:
    let
      cfg = config.dawo.ssh;
    in
    {
      options.dawo.ssh = {
        enable = lib.mkEnableOption "hardened OpenSSH crypto + login policy (NCSC/CIS)";
        options.maxAuthTries = lib.mkOption {
          type = lib.types.ints.positive;
          default = 4;
          description = "Max authentication attempts per connection (must be > 0).";
        };
      };

      config = lib.mkIf cfg.enable {
        # Guard the "no empty/undefined option" rule (#8): a non-positive value
        # would disable the limit. The positive type already rejects <= 0; the
        # assertion documents the intent and gives a readable build-time error.
        assertions = [
          {
            assertion = cfg.options.maxAuthTries > 0;
            message = "dawo.ssh.options.maxAuthTries must be > 0 (0 disables the login-attempt limit).";
          }
        ];

        services.openssh = {
          enable = lib.mkForce true;
          settings = {
            Banner = lib.mkForce "/etc/issue.net";
            # Tunable: a suggested default a host may raise/lower.
            MaxAuthTries = lib.mkDefault cfg.options.maxAuthTries;
          };
        };
      };
    };
}
