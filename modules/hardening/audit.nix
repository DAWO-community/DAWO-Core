{
  # auditd (BIO detection). Norm: ANSSI R33 + BIO (non-repudiation). Origin:
  # securix.
  #
  # This used to be a warning and nothing else: auditctl 4.1.2-unstable
  # rejected line 2 of every rules file NixOS generated, so real rules broke
  # `nixos-rebuild switch`. audit 4.2.1 in the current lock loads them; checked
  # in a VM test that boots with the rules below, lists them with `auditctl -l`
  # and finds a user's command back with `ausearch`.
  #
  # The ruleset records who changed an account, who became root and what they
  # ran, and what touched the kernel. It leaves out an execve rule for every
  # process: on a desktop that is most of the disk traffic and says little.
  #
  # Not set: `-e 2` (rules immutable until reboot). It would make every switch
  # that changes a rule fail until the device restarts. Also not set: a watch
  # on /var/log/audit. The rules load before auditd creates that directory,
  # and one missing path fails the whole unit.
  flake.modules.nixos.hardening-audit =
    { config, lib, ... }:
    let
      cfg = config.dawo.audit;

      # Both ABIs, or a 32-bit binary walks past a 64-bit-only rule.
      syscall =
        calls: key:
        map (arch: "-a always,exit -F arch=${arch} -S ${calls} ${key}") [
          "b64"
          "b32"
        ];
      byUser = "-F auid>=1000 -F auid!=unset";
    in
    {
      options.dawo.audit.enable = lib.mkEnableOption "auditd with the DAWO ruleset (BIO)";

      config = lib.mkIf cfg.enable {
        security.auditd.enable = true;
        security.audit.enable = true;
        security.audit.rules =
          map (path: "-a always,exit -F path=${path} -F perm=wa -k identity") [
            "/etc/passwd"
            "/etc/shadow"
            "/etc/group"
            "/etc/gshadow"
          ]
          ++ [ "-a always,exit -F path=/etc/sudoers -F perm=wa -k privilege" ]
          ++ syscall "execve" "-F euid=0 ${byUser} -k privileged"
          ++ syscall "init_module,finit_module,delete_module" "-k modules";

        # Retention, written down rather than inherited: five files of 8 MiB,
        # the oldest rotated out. Enough for weeks on a desktop with the rules
        # above. Forwarding off the device is not decided yet (#109).
        security.auditd.settings = {
          max_log_file = 8;
          num_logs = 5;
          max_log_file_action = "rotate";
        };
      };
    };
}
