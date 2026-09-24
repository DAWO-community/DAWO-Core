{
  # Fleet auto-update via comin (git-driven reconcile). Tracks a flake on
  # Codeberg and rebuilds the device when new commits land.
  #
  # A bare device tracks the upstream core (DAWO-NixOS). A workplace points
  # repoUrl at its own overlay flake, which consumes the core as an input, so
  # the chosen overlay is pulled in on every update. Follows the dawo.<block>
  # interface; replaces the hard-wired services-comin.
  flake.modules.nixos.services-auto-update =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      cfg = config.dawo.autoUpdate;

      # comin hands auth.username straight to go-git as the SSH user
      # (ssh.NewPublicKeysFromFile(username, key, "")), where it REPLACES the
      # user the URL names, and its own default is "comin" - an account on no
      # forge. A deploy key that is in fact correct then fails every poll with
      # "no supported methods remain", and the message points at the key. So
      # read the user off the URL rather than asking a deployment to write it a
      # second time and letting the two drift.
      #
      # builtins.match anchors on the whole string, so the two forms cannot be
      # confused for one another.
      sshUserFromUrl =
        url:
        let
          withScheme = builtins.match "[a-zA-Z0-9+.-]+://([^@/]+)@.*" url; # ssh://git@host/path
          scpLike = builtins.match "([^@/:]+)@[^@/:]+:.*" url; # git@host:path
        in
        if withScheme != null then
          builtins.head withScheme
        else if scpLike != null then
          builtins.head scpLike
        else
          "git";

      # A deploy key does nothing for an https:// remote - comin would carry it
      # and still authenticate as nobody. Worth catching at eval rather than
      # letting it become another silent failed poll.
      isSshUrl =
        url: builtins.match "ssh://.*" url != null || builtins.match "[^@/:]+@[^@/:]+:.*" url != null;
    in
    {
      # Renamed in 0.2: the `options` level went away. Kept for one release.
      imports = [
        inputs.comin.nixosModules.comin

        # Renamed in 0.2: the `options` level went away. Kept for one release.
        (lib.mkRenamedOptionModule
          [ "dawo" "autoUpdate" "options" "repoUrl" ]
          [ "dawo" "autoUpdate" "repoUrl" ]
        )
        (lib.mkRenamedOptionModule
          [ "dawo" "autoUpdate" "options" "branch" ]
          [ "dawo" "autoUpdate" "branch" ]
        )
        (lib.mkRenamedOptionModule
          [ "dawo" "autoUpdate" "options" "pollSeconds" ]
          [ "dawo" "autoUpdate" "pollSeconds" ]
        )
        (lib.mkRenamedOptionModule
          [ "dawo" "autoUpdate" "options" "sshDeployKeyPath" ]
          [ "dawo" "autoUpdate" "sshDeployKeyPath" ]
        )
        (lib.mkRenamedOptionModule
          [ "dawo" "autoUpdate" "options" "knownHostsPath" ]
          [ "dawo" "autoUpdate" "knownHostsPath" ]
        )
      ];

      options.dawo.autoUpdate = {
        enable = lib.mkEnableOption "git-driven auto-update via comin";
        repoUrl = lib.mkOption {
          type = lib.types.str;
          default = "https://codeberg.org/DAWO/DAWO-Core.git";
          description = ''
            Git repository to track. A bare device tracks the upstream core; a
            workplace points this at its own overlay flake (which consumes the
            DAWO core as an input) so the chosen overlay rides along.

            The default is the address the core moved to. A device that was
            imaged before the move and never had this set keeps polling the old
            one until it takes an update that carries this change, which it
            cannot take from a repository that no longer moves: such a device
            has to be pointed at the new URL by hand once.
          '';
        };
        branch = lib.mkOption {
          type = lib.types.str;
          default = "main";
          description = "Branch to follow on repoUrl.";
        };
        pollSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1800;
          description = "Poll interval in seconds (must be > 0).";
        };
        sshDeployKeyPath = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "/run/agenix/comin-deploy-key";
          description = ''
            Path on the device to a read-only SSH deploy key for repoUrl. Empty
            (the default) means no credential, which is right for a public
            repository.

            A private overlay needs this. A netrc gives *nix* a credential,
            which is what nix needs to fetch a private flake input, but comin
            does not fetch through nix: it clones the repository itself, with
            its own git client, reading this. Without it such a deployment
            authenticates for the rebuild and not for the pull that triggers it,
            and comin logs the failed pull at error level and goes back to
            sleep. The only symptom is a device that quietly stops moving.

            A deploy key rather than an account token: a token can read every
            repository its account can read, and it would sit on every device in
            the fleet. A deploy key reads one repository and cannot write to it.

            This is a runtime path, deliberately a string rather than a path:
            a Nix path literal would copy the private key into /nix/store, where
            it is world readable. There is an assertion for that.
          '';
        };
        knownHostsPath = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "/etc/ssh/ssh_known_hosts";
          description = ''
            Path to a known_hosts file carrying the host key of repoUrl. Empty
            means comin falls back to /etc/ssh/ssh_known_hosts.

            Pin it rather than trusting on first use: these devices roam across
            networks nobody here runs, and trust on first use trusts whatever
            answers first. A store path is fine here - host keys are public.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.repoUrl != "";
            message = "dawo.autoUpdate.repoUrl must be set (the image/overlay flake to track).";
          }
          {
            assertion = !(lib.hasPrefix builtins.storeDir cfg.sshDeployKeyPath);
            message = ''
              dawo.autoUpdate.sshDeployKeyPath points into the Nix store,
              which is world readable, so the private key would be published to
              every user of the device. Give it a runtime path instead - an
              agenix secret path, or a file placed by the imaging step.
            '';
          }
          {
            assertion = cfg.sshDeployKeyPath == "" || isSshUrl cfg.repoUrl;
            message = ''
              dawo.autoUpdate.sshDeployKeyPath is set but repoUrl is not
              an SSH remote (${cfg.repoUrl}), so the key would never be
              used and every poll would fail as unauthenticated. Point repoUrl at
              the ssh:// or git@host:path form of the same repository.
            '';
          }
        ];

        services.comin = {
          enable = true;
          remotes = [
            {
              name = "dawo-image";
              url = cfg.repoUrl;
              branches.main.name = cfg.branch;
              poller.period = cfg.pollSeconds;
              auth = {
                ssh_deploy_key_path = cfg.sshDeployKeyPath;
                ssh_known_hosts_path = cfg.knownHostsPath;
              }
              # Only take the username over when there is a key to use it with.
              # comin also reads it for the HTTPS token helper, and a deployment
              # on that path should keep whatever it set.
              // lib.optionalAttrs (cfg.sshDeployKeyPath != "") {
                username = sshUserFromUrl cfg.repoUrl;
              };
            }
          ];
        };
      };
    };
}
