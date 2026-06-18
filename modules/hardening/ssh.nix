{
  # SSH hardening (CIS/NCSC). MANDATORY-core tier.
  # Does NOT touch PasswordAuthentication (per-host call). Norm: NCSC SSH/TLS
  # crypto + CIS-DIL -> BIO. See architecture.md "Key Design Decisions".
  #
  # The crypto floor and login policy are forced (lib.mkForce) so a host cannot
  # silently weaken them; maxAuthTries is a suggested default a host may tune.
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
            # Forced: the mandatory crypto + login floor.
            PermitRootLogin = lib.mkForce "no";
            KbdInteractiveAuthentication = lib.mkForce false;
            Banner = lib.mkForce "/etc/issue.net";
            Ciphers = lib.mkForce [
              "chacha20-poly1305@openssh.com"
              "aes256-gcm@openssh.com"
              "aes128-gcm@openssh.com"
            ];
            KexAlgorithms = lib.mkForce [
              "curve25519-sha256"
              "curve25519-sha256@libssh.org"
              "diffie-hellman-group16-sha512"
            ];
            Macs = lib.mkForce [
              "hmac-sha2-512-etm@openssh.com"
              "hmac-sha2-256-etm@openssh.com"
            ];
            # Tunable: a suggested default a host may raise/lower.
            MaxAuthTries = lib.mkDefault cfg.options.maxAuthTries;
          };
        };
      };
    };
}
