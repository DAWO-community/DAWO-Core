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
            sshOpts = [
              "-o BatchMode=yes"
              "-o StrictHostKeyChecking=no"
              "-o UserKnownHostsFile=/dev/null"
            ];
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
