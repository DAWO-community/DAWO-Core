{
  inputs,
  ...
}:
{
  imports = [
    inputs.make-shell.flakeModules.default
  ];

  perSystem =
    { pkgs, ... }:
    {
      make-shells.default = {
        packages = [
          pkgs.deploy-rs
        ];
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
            # deliberately, checking the fingerprint against the device rather
            # than against the network:
            #
            #   ssh-keyscan <host> >> ~/.ssh/known_hosts
            #
            # and compare with `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`
            # read off the machine itself.
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
