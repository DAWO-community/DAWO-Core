{
  # Coverage gate. `nix flake check` fails when a host loses something the
  # baseline promises. Cheap eval-time assertions on a Plasma and a GNOME host,
  # no VM boot.
  #
  # It used to assert six functional claims and no security control at all,
  # which is how a missing screen lock, an unimported hardening tier and an
  # auditd that does nothing all passed. Both halves are here now: what a device
  # has to be able to do, and what it has to refuse.
  #
  # Add a line whenever the baseline promises something new. A rule in the
  # register carries its own check on the device; this is the build-time half,
  # for the promises that are not rules yet.
  flake =
    { lib, config, ... }:
    let
      hosts = {
        plasma = config.nixosConfigurations.dawo-hp-probook-4g1i;
        gnome = config.nixosConfigurations.dawo-t495s-gnome;
      };
      pkgs = hosts.plasma.pkgs;
      # Inside `flake = { config, ... }` this config is the flake submodule, so
      # the register declared at flake.dawo.rules is reached without the prefix.
      register = config.dawo.rules;

      hasFont = cfg: needle: lib.any (p: lib.hasInfix needle (p.name or "")) cfg.config.fonts.packages;
      hasPkg = cfg: needle: lib.any (p: lib.hasInfix needle (p.name or "")) cfg.config.environment.systemPackages;
      sshd = cfg: cfg.config.services.openssh.settings;
      sysctl = cfg: key: cfg.config.boot.kernel.sysctl.${key} or null;

      # What a device has to be able to do. These caught real gaps: silent
      # GNOME audio, and a missing CUPS.
      works = name: cfg: [
        {
          n = "${name}: PipeWire audio";
          ok = cfg.config.services.pipewire.enable;
        }
        {
          n = "${name}: SANE scanning";
          ok = cfg.config.hardware.sane.enable;
        }
        {
          n = "${name}: NetworkManager";
          ok = cfg.config.networking.networkmanager.enable;
        }
        {
          n = "${name}: color emoji font";
          ok = hasFont cfg "noto-fonts-color-emoji";
        }
        {
          n = "${name}: dawo-update-status shipped";
          ok = hasPkg cfg "dawo-update-status";
        }
      ];

      # What a device has to refuse. One line per promise the baseline makes,
      # so that dropping the promise fails the build rather than the audit.
      refuses = name: cfg: [
        {
          n = "${name}: no generic autoUpgrade (comin only)";
          ok = !cfg.config.system.autoUpgrade.enable;
        }
        {
          n = "${name}: sshd refuses root";
          ok = (sshd cfg).PermitRootLogin == "no";
        }
        {
          n = "${name}: sshd refuses passwords";
          ok = (sshd cfg).PasswordAuthentication == false;
        }
        {
          n = "${name}: sshd carries the crypto floor";
          ok = lib.elem "chacha20-poly1305@openssh.com" ((sshd cfg).Ciphers or [ ]);
        }
        {
          n = "${name}: firewall up";
          ok = cfg.config.networking.firewall.enable;
        }
        {
          n = "${name}: kernel pointers hidden";
          ok = sysctl cfg "kernel.kptr_restrict" == 2;
        }
        {
          n = "${name}: kexec disabled";
          ok = sysctl cfg "kernel.kexec_load_disabled" == 1;
        }
        {
          n = "${name}: ptrace restricted";
          ok = (sysctl cfg "kernel.yama.ptrace_scope") == 1;
        }
        {
          n = "${name}: sudo only for wheel";
          ok = cfg.config.security.sudo.execWheelOnly;
        }
        {
          n = "${name}: the screen locks itself";
          ok =
            (cfg.config.environment.etc."xdg/kscreenlockerrc".text or "") != ""
            && lib.any (
              db: lib.elem "/org/gnome/desktop/screensaver/lock-enabled" (db.locks or [ ])
            ) cfg.config.programs.dconf.profiles.user.databases;
        }
        {
          n = "${name}: the device can check itself";
          ok = hasPkg cfg "dawo-verify";
        }
      ];

      # A rule nobody can check is a claim, not a control. This is the gate that
      # keeps the register honest as it grows.
      registerIsHonest = lib.mapAttrsToList (id: rule: {
        n = "register: ${id} carries a check and a reason";
        ok = (rule.verify or "") != "" && (rule.why or "") != "" && (rule.severity or "") != "";
      }) register;

      claims = name: cfg: works name cfg ++ refuses name cfg;
      fails = lib.filter (c: !c.ok) (
        lib.concatLists (lib.mapAttrsToList claims hosts) ++ registerIsHonest
      );
    in
    {
      checks.x86_64-linux.workplace-baseline =
        if fails == [ ] then
          pkgs.runCommand "workplace-baseline-ok" { } "echo 'workplace baseline OK' > $out"
        else
          throw "workplace-baseline GAP(s): ${lib.concatMapStringsSep "; " (c: c.n) fails}";
    };
}
