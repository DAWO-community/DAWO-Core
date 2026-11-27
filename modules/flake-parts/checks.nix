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
      hasPkg =
        cfg: needle: lib.any (p: lib.hasInfix needle (p.name or "")) cfg.config.environment.systemPackages;
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
          n = "${name}: KDE Connect ports closed unless a deployment opts in";
          ok =
            !lib.any (r: r.from <= 1716 && 1716 <= r.to) (
              cfg.config.networking.firewall.allowedTCPPortRanges
              ++ cfg.config.networking.firewall.allowedUDPPortRanges
            );
        }
        {
          n = "${name}: no D-Bus policy lets users own org.bluez";
          ok =
            !lib.any (p: lib.hasInfix ''own="org.bluez"'' (p.text or "")) cfg.config.services.dbus.packages;
        }
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

      # The lockout's rules sit among rules NixOS generates, and which ones a
      # stack holds depends on the host. Checked on each host and once more
      # with SSSD on, the composition that broke it twice: a shared order that
      # failed the eval, and an account phase that ended before faillock.
      pamHosts = hosts // {
        plasma-sssd = hosts.plasma.extendModules { modules = [ { services.sssd.enable = true; } ]; };
      };
      lockout =
        name: cfg:
        let
          listed = cfg.config.dawo.pam.lockout.services;
          rules =
            svc: type:
            lib.filterAttrs (_: r: r.enable) (cfg.config.security.pam.services.${svc}.rules.${type} or { });
          orders =
            svc: type: control:
            lib.mapAttrsToList (_: r: r.order) (lib.filterAttrs (_: r: r.control == control) (rules svc type));
          auth = svc: rules svc "auth";
          includes =
            svc:
            lib.concatMap
              (
                type:
                lib.mapAttrsToList (_: r: r.modulePath) (
                  lib.filterAttrs (
                    _: r:
                    lib.elem r.control [
                      "include"
                      "substack"
                    ]
                  ) (rules svc type)
                )
              )
              [
                "account"
                "auth"
                "password"
                "session"
              ];
          perService = svc: [
            {
              n = "${name}: ${svc} points faillock at the policy in /etc";
              ok = lib.all (r: lib.elem "conf=/etc/security/faillock.conf" (r.args or [ ])) [
                (rules svc "account").faillock
                (auth svc).faillockPreauth
                (auth svc).faillockAuthfail
              ];
            }
            {
              n = "${name}: ${svc} counts a failure after every password check";
              ok = lib.all (o: o < (auth svc).faillockAuthfail.order) (orders svc "auth" "sufficient");
            }
            {
              n = "${name}: ${svc} counts a failure before the final deny";
              ok = !(auth svc ? deny) || (auth svc).faillockAuthfail.order < (auth svc).deny.order;
            }
            {
              n = "${name}: ${svc} clears the count before the account phase can end";
              ok = lib.all (o: (rules svc "account").faillock.order < o) (orders svc "account" "sufficient");
            }
            {
              n = "${name}: ${svc} does not include a service the lockout already guards";
              ok = !lib.any (m: lib.elem m listed) (includes svc);
            }
          ];
        in
        [
          {
            n = "${name}: lockout covers polkit";
            ok = lib.elem "polkit-1" listed;
          }
          {
            n = "${name}: lockout covers the Plasma screen locker";
            ok = !cfg.config.services.desktopManager.plasma6.enable || lib.elem "kde" listed;
          }
        ]
        ++ lib.concatMap perService listed;

      # A rule nobody can check is a claim, not a control. This is the gate that
      # keeps the register honest as it grows.
      registerIsHonest = lib.mapAttrsToList (id: rule: {
        n = "register: ${id} carries a check and a reason";
        ok = (rule.verify or "") != "" && (rule.why or "") != "" && (rule.severity or "") != "";
      }) register;

      # Combinations the build has to refuse. Each guard is an assertion, and
      # an assertion that stops firing turns a refusal into a silent default,
      # so each one is tried on each host: once where it must fire, and once
      # for every way out it offers.
      guards =
        name: cfg:
        let
          refused =
            needle: modules:
            lib.any (a: !a.assertion && lib.hasInfix needle a.message)
              (cfg.extendModules { inherit modules; }).config.assertions;
          # Secure Boot is forced either way, since a host may set it itself.
          tpm2Refused =
            secureboot: extra:
            refused "dawo.diskUnlock.tpm2.enable is on while" [
              {
                dawo.diskUnlock.tpm2.enable = true;
                dawo.secureboot.enable = lib.mkForce secureboot;
              }
              extra
            ];
        in
        [
          {
            n = "${name}: TPM2 unlock without Secure Boot is refused";
            ok = tpm2Refused false { };
          }
          {
            n = "${name}: TPM2 unlock with Secure Boot is allowed";
            ok = !tpm2Refused true { };
          }
          {
            n = "${name}: TPM2 unlock on a bench machine that says so is allowed";
            ok = !tpm2Refused false { dawo.diskUnlock.tpm2.allowWithoutSecureBoot = true; };
          }
        ];

      claims = name: cfg: works name cfg ++ refuses name cfg ++ guards name cfg;
      fails = lib.filter (c: !c.ok) (
        lib.concatLists (lib.mapAttrsToList claims hosts)
        ++ lib.concatLists (lib.mapAttrsToList lockout pamHosts)
        ++ registerIsHonest
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
