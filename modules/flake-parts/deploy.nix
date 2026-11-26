{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.make-shell.flakeModules.default
  ];

  perSystem =
    { pkgs, lib, ... }:
    {
      make-shells.default = {
        packages = [
          pkgs.deploy-rs
        ];
      };

      # A real deploy-rs run against a device built with the core's deploy
      # account, using the settings every node gets from the block below.
      # Both halves of a deploy go through sudo on the device, activation and
      # the magic-rollback confirmation, and a sudo rule that does not match
      # shows up nowhere but here: every deploy rolls back after
      # confirmTimeout. So this deploys twice and checks that both stay, then
      # cuts the network during a third and checks that the device goes back
      # to the second by itself. It also checks that an unknown host key stops
      # the deploy before anything is copied.
      #
      # The profile is a small custom one, not a whole NixOS system: what is
      # under test is the way in, not what gets activated. Needs KVM.
      checks.deploy-rs-vm =
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          node = lib.head (lib.attrValues config.flake.deploy.nodes);
          settings = pkgs.writeText "settings.json" (
            builtins.toJSON {
              inherit (node) fastConnection sshOpts;
              inherit (node.profiles.system)
                sshUser
                user
                interactiveSudo
                magicRollback
                confirmTimeout
                ;
            }
          );
          inherit (node.profiles.system) confirmTimeout;
          activate = inputs.deploy-rs.packages.${system}.default;
          keys = import "${pkgs.path}/nixos/tests/ssh-keys.nix" pkgs;
          flake = pkgs.replaceVars ./deploy-rs-vm/flake.nix.in {
            inherit system activate;
            inherit (pkgs) bash coreutils iptables;
          };
          # Store paths the test flake names. Its derivations have no context,
          # so the deployer builds them unsandboxed, and deploy-rs copies only
          # the profile itself: both machines need these already.
          storePaths = [
            activate
            pkgs.bash
            pkgs.coreutils
            pkgs.iptables
          ];
        in
        pkgs.testers.runNixOSTest {
          name = "deploy-rs";
          nodes.device = {
            imports = [ config.flake.modules.nixos.users-deploy ];
            # Forced on by the hardening baseline on every real device.
            security.sudo.execWheelOnly = true;
            services.openssh.enable = true;
            users.users.deploy.openssh.authorizedKeys.keys = [ keys.snakeOilPublicKey ];
            virtualisation.additionalPaths = storePaths;
          };
          nodes.deployer = {
            # What docs/deploy.md has the operator run.
            environment.systemPackages = [ pkgs.deploy-rs ];
            nix.settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              sandbox = false;
              substituters = lib.mkForce [ ];
            };
            virtualisation.additionalPaths = storePaths;
          };
          testScript = ''
            start_all()
            deployer.succeed("mkdir -p /root/.ssh /root/d")
            deployer.succeed("cp ${flake} /root/d/flake.nix && cp ${settings} /root/d/settings.json")
            deployer.succeed("install -m 600 ${keys.snakeOilPrivateKey} /root/.ssh/id_ed25519")
            deployer.succeed("cd /root/d && nix flake lock")
            # Building the test profiles in this VM is killed (signal 9) in
            # about half the runs, for reasons that have nothing to do with
            # what is under test. Build them up front, retrying, so the build
            # step inside deploy-rs finds them done.
            for gen in [1, 2, 3]:
                deployer.wait_until_succeeds(
                    f"cd /root/d && nix build --no-link .#deploy.nodes.gen{gen}.profiles.test.path",
                    timeout=120,
                )
            device.wait_for_open_port(22)

            # activate-rs keeps a root profile other than the system one under
            # per-user/root, or under root's ~/.local/state on newer layouts.
            def profile_link():
                return device.succeed(
                    "readlink $(ls -d /nix/var/nix/profiles/per-user/root/test"
                    " /root/.local/state/nix/profiles/test 2>/dev/null | head -1)"
                ).strip()

            def deploy(gen):
                return f"cd /root/d && deploy --skip-checks .#gen{gen}.test 2>&1"

            with subtest("an unknown host key stops the deploy"):
                out = deployer.fail(deploy(1))
                assert "Host key verification failed" in out, out
                device.fail("test -e /run/generation")

            # The way docs/deploy.md adds a key: compare first, then trust.
            deployer.succeed("ssh-keyscan -t ed25519 device > /root/device.key")
            fp = deployer.succeed("ssh-keygen -lf /root/device.key").split()[1]
            assert fp in device.succeed("ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub")
            deployer.succeed("cat /root/device.key >> /root/.ssh/known_hosts")

            for gen in [1, 2]:
                with subtest(f"deploy {gen} is confirmed and stays"):
                    out = deployer.succeed(deploy(gen))
                    assert "Deployment confirmed" in out, out
                    device.sleep(${toString (confirmTimeout + 5)})
                    assert device.succeed("cat /run/generation").strip() == str(gen)
                    assert profile_link() == f"test-{gen}-link", profile_link()

            with subtest("a device that drops off during activation rolls back by itself"):
                deployer.fail(deploy(3), timeout=600)
                device.wait_until_succeeds("test $(cat /run/generation) = 2", timeout=120)
                assert profile_link() == "test-2-link", profile_link()
          '';
        };
    };

  flake =
    { lib, config, ... }:
    {
      deploy.nodes = lib.mapAttrs' (
        hostname: nixosConfiguration:
        let
          inherit (nixosConfiguration.config.nixpkgs.hostPlatform) system;
        in
        {
          name = hostname;
          value = {
            inherit hostname;
            fastConnection = true;
            # BatchMode only: never prompt, and fail rather than ask. The two
            # options that used to sit here, StrictHostKeyChecking=no and
            # UserKnownHostsFile=/dev/null, accepted whatever host key answered
            # while pushing a closure that is then activated as root. That is
            # the same trust-on-first-use the auto-update block refuses for
            # comin, on a path with more privilege.
            #
            # A host key that is not yet known now stops the deploy. Add it
            # deliberately, and compare before trusting it: scan the key to a
            # file, compare its fingerprint with what the device itself shows,
            # and only then append it to known_hosts:
            #
            #   ssh-keyscan -t ed25519 <host> > host.key
            #   ssh-keygen -lf host.key
            #   # on the device: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
            #   cat host.key >> ~/.ssh/known_hosts   # only if they match
            sshOpts = [ "-o BatchMode=yes" ];
            profiles.system = {
              sshUser = "deploy";
              user = "root";
              interactiveSudo = false;
              # Roll back when the new generation cannot be reached after
              # activation. A laptop that loses its network on switch is the
              # normal case this exists for, and the alternative is a device
              # that has to be visited.
              magicRollback = true;
              remoteBuild = false;
              confirmTimeout = 30;
              path = inputs.deploy-rs.lib.${system}.activate.nixos nixosConfiguration;
            };
          };
        }
      ) config.nixosConfigurations;
    };
}
