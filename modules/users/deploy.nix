{
  flake.modules.nixos.users-deploy = _: {
    users = {
      mutableUsers = true;
      users = {
        deploy = {
          description = "NixOS Deploy";
          home = "/home/deploy";
          group = "users";
          createHome = true;
          homeMode = "700";
          # No password. The account is reached with an SSH key the
          # organisation overlay installs, and a hash in a public repository
          # is a credential published to everyone who clones it.
          isSystemUser = true;
          isNormalUser = false;
          # A system user gets nologin as its shell unless told otherwise,
          # and deploy-rs reaches the device by running commands over SSH
          # (nix-store --serve, then sudo). With nologin every deploy stops at
          # the copy step. users.defaultUserShell is bash; zsh is opt-in via
          # dawo.zsh.enable.
          useDefaultShell = true;
          # wheel is required, not decorative: security.sudo.execWheelOnly is
          # forced on in hardening/sysctl-baseline.nix, so a non-wheel user
          # cannot run sudo at all, including the rule below.
          # nixbld is deliberately absent: those are the daemon's own build
          # users and membership does nothing for a deploy account.
          extraGroups = [
            "wheel"
            "podman"
          ];
          # No keys in the generic core. SSH admin/deploy keys are added by the
          # organisation overlay (e.g. Zaanstad), per ADR-0001/0003.
          openssh.authorizedKeys.keys = [ ];
        };
      };
    };
    # deploy-rs copies an unsigned closure to the device before activating it,
    # and the daemon only accepts that from a trusted user. Without this the
    # push fails and the alternative is signing every closure, which needs a
    # key on the builder and a public key on every device.
    nix.settings.trusted-users = [ "deploy" ];

    # deploy-rs activates by running "sudo -u root <closure>/activate-rs ...",
    # so that is the only command this account needs (verified against
    # deploy-rs's own command builder in src/deploy.rs).
    #
    # Being honest about what this buys: it narrows the command surface, and
    # it does not make the account non-root-equivalent. Any user can add a
    # path to the store, so a path matching this pattern can be produced
    # rather than only received. What actually gates this account is the SSH
    # key the overlay installs; a device where that key leaks is lost either
    # way. Written down so the next reader does not mistake the rule for a
    # boundary it is not.
    security.sudo.extraRules = [
      {
        users = [ "deploy" ];
        commands = [
          {
            command = "/nix/store/*/activate-rs";
            options = [ "NOPASSWD" ];
          }
          # With magic rollback, deploy-rs confirms a deployment by running
          # "sudo -u root rm <temp>/deploy-rs-canary-<hash>" (confirm_profile
          # in src/deploy.rs). Without this rule the confirmation fails and the
          # device rolls back after confirmTimeout. The path is matched by
          # inode and the argument by a regular expression, so this allows
          # removing that one file and nothing else.
          {
            command = "/run/current-system/sw/bin/rm ^/tmp/deploy-rs-canary-[0-9a-z]{32}$";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
