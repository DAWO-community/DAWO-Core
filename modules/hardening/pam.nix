{
  # Login policy: what happens when somebody guesses, and what a password has to
  # look like. Until now the image had no PAM configuration at all, so an
  # attacker at the keyboard could try passwords for as long as they liked, and
  # a user could set one letter.
  #
  # Everything here is a lockout risk by nature, so two rules run through it.
  # Nothing locks root, and nothing locks forever: a lockout expires on its own,
  # so a mistake costs a wait rather than a visit. Both are options, and both
  # defaults are chosen to fail towards a device somebody can still use.
  flake.modules.nixos.hardening-pam =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.pam;

      faillock = "${pkgs.linux-pam}/lib/security/pam_faillock.so";
      pwquality = "${pkgs.libpwquality}/lib/security/pam_pwquality.so";

      # A host without a desktop module has no dawo.desktop at all, so the
      # services default reads the desktop options through this guard.
      desktopEnable = name: lib.attrByPath [ "dawo" "desktop" name "enable" ] false config;

      # Where the rules go, relative to the rules NixOS generates for a
      # service rather than at fixed numbers: which modules a stack holds, and
      # so their orders, depends on what else the host enables (SSSD puts its
      # auth rule at 13300, Kerberos and LDAP add their own).
      #
      #  - account faillock goes in front of every generated account rule
      #    (they start at 10100). The first `sufficient` account module ends
      #    the phase, and this is the call that clears the failure count after
      #    a good login; behind pam_sss it never ran for a directory user.
      #  - preauth goes before the password is checked (unix-early is 11700).
      #  - authfail goes right before the final deny, so after every module
      #    that can check the password, whichever those are.
      orderBeforeDeny =
        svc: lib.attrByPath [ "services" svc "rules" "auth" "deny" "order" ] 13700 config.security.pam - 10;

      lockoutRules = svc: {
        account.faillock = {
          order = 10000;
          control = "required";
          modulePath = faillock;
        };
        auth.faillockPreauth = {
          order = 11500;
          control = "required";
          modulePath = faillock;
          args = [
            "preauth"
            "silent"
          ];
        };
        auth.faillockAuthfail = {
          order = orderBeforeDeny svc;
          control = "required";
          modulePath = faillock;
          args = [ "authfail" ];
        };
      };
    in
    {
      options.dawo.pam = {
        lockout = {
          enable = lib.mkEnableOption "lock an account after repeated failed logins" // {
            default = true;
          };

          attempts = lib.mkOption {
            type = lib.types.ints.positive;
            default = 5;
            description = ''
              Failed attempts before the account locks. Low enough to stop
              guessing, high enough to survive a keyboard layout somebody did
              not expect.
            '';
          };

          unlockSeconds = lib.mkOption {
            type = lib.types.ints.positive;
            default = 600;
            description = ''
              How long a lockout lasts. It expires on its own, on purpose: a
              lock that only an administrator can lift turns a typo on a train
              into a day without a laptop.
            '';
          };

          services = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            # Every service here has a password check of its own. The display
            # managers are not listed: sddm and gdm-password authenticate with
            # `substack login`, so login's rules already guard them, and
            # listing them ran faillock a second time after the substack,
            # where authfail runs on every attempt and counted each good
            # login as a failure. The Plasma screen locker (kde) and polkit
            # do not include login and are listed for that reason.
            default = [
              "login"
              "su"
              "sudo"
            ]
            ++ lib.optional (desktopEnable "plasma") "kde"
            ++ lib.optional config.security.polkit.enable "polkit-1";
            defaultText = lib.literalMD "the console (which covers SDDM and GDM), su, sudo, polkit, and the Plasma screen locker";
            description = ''
              PAM services the lockout applies to. Every place a password can be
              typed belongs here, directly or through a listed service its stack
              includes; a service left out is a way around it. A service that
              includes or substacks a listed one must not be listed itself, or a
              good password counts as a failure.
            '';
          };
        };

        quality = {
          enable = lib.mkEnableOption "require a password that is not trivially guessable" // {
            default = true;
          };

          minLength = lib.mkOption {
            type = lib.types.ints.positive;
            default = 12;
            description = ''
              Minimum length. Length beats character classes: a long passphrase
              somebody can remember is worth more than eight characters with a
              symbol they wrote on a sticky note.
            '';
          };
        };

        u2f = {
          enable = lib.mkEnableOption ''
            a hardware key (FIDO2) as a second factor for login and sudo. Off by
            default and deliberately so: every user needs an enrolled key and a
            recovery path before this is turned on, or it is a lockout with
            extra steps. See docs/users.md
          '';
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.lockout.enable {
          # pam_faillock reads its numbers here rather than from the module
          # arguments, so one file answers "what is the policy" for every
          # service it is wired into.
          environment.etc."security/faillock.conf".text = ''
            deny = ${toString cfg.lockout.attempts}
            unlock_time = ${toString cfg.lockout.unlockSeconds}
            fail_interval = 900
            # root is never locked out: the account that fixes a locked device
            # is not the one to lock.
            silent
          '';

          security.pam.services = lib.genAttrs cfg.lockout.services (svc: {
            rules = lockoutRules svc;
          });

          environment.systemPackages = [ pkgs.linux-pam ]; # faillock(8), to see and clear a lock
        })

        (lib.mkIf cfg.quality.enable {
          environment.etc."security/pwquality.conf".text = ''
            minlen = ${toString cfg.quality.minLength}
            # One repeat and one class rule, and no more: piling on requirements
            # produces Zomer2026! on every device in the building.
            maxrepeat = 3
            minclass = 2
            enforce_for_root
          '';

          # Before pam_unix, which is `sufficient` at order 10200: a password
          # stack short-circuits on the first success, so a check that runs
          # after it never runs at all.
          security.pam.services.passwd.rules.password.pwquality = {
            order = 10100;
            control = "required";
            modulePath = pwquality;
            args = [ "retry=3" ];
          };
        })

        (lib.mkIf cfg.u2f.enable {
          security.pam.u2f = {
            enable = true;
            settings.cue = true; # say "touch your key" rather than appearing to hang
          };
          security.pam.services = lib.genAttrs cfg.lockout.services (_: {
            u2fAuth = true;
          });
        })
      ];
    };
}
