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
              magicRollback = false;
              remoteBuild = false;
              confirmTimeout = 30;
              path = inputs.deploy-rs.lib.${system}.activate.nixos nixosConfiguration;
            };
          };
        }
      ) config.nixosConfigurations;
    };
}
