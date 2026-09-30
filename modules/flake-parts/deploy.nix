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
    let
      # The only source of host keys a deploy trusts (#103). Everything else
      # is turned off: accepting whatever answers first is how a deploy that
      # activates a root closure becomes remote code execution by any device
      # on the path. Host keys are public, so a store path is fine here.
      knownHosts = builtins.toString ./../hosts/known_hosts;
    in
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
            sshOpts = [
              "-o BatchMode=yes"
              # Verify against the fleet's known_hosts and nothing else. The
              # system-wide /etc file is excluded on purpose: a deploy should
              # fail on a key this repository does not vouch for, and a host
              # that is not recorded yet is a host that cannot be deployed to
              # until it is (see docs/deploy.md).
              "-o GlobalKnownHostsFile=/dev/null"
              "-o UserKnownHostsFile=${knownHosts}"
              "-o StrictHostKeyChecking=yes"
            ];
            profiles.system = {
              sshUser = "deploy";
              user = "root";
              interactiveSudo = false;
              # Rollback verification back on (#103): the new generation must
              # report in over SSH before the old one is dropped, so a config
              # that breaks boot rolls the device back instead of leaving it
              # dead. The device must be able to reach the operator back for
              # this - on the provisioning LAN it always can; on a one-way NAT
              # a deploy fails safe rather than skipping verification.
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
