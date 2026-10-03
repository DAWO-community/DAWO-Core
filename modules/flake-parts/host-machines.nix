{
  inputs,
  lib,
  config,
  ...
}:
let
  prefix = "hosts/";
in
{
  flake.nixosConfigurations = lib.pipe config.flake.modules.nixos [
    (lib.filterAttrs (name: _: lib.hasPrefix prefix name))
    (lib.mapAttrs' (
      name: module:
      let
        specialArgs = {
          inputs = abort ''
            In DAWO-Core we avoid a possible inputs module argument, because using it would require third-party flakes to pass DAWO-Core's own inputs as specialArgs.inputs, which is inconvenient and collides with how they may want to use the inputs argument for themselves.
            Instead, you can use the `inputs` argument at the flake-parts level, which is always the DAWO-Core inputs. This way we keep the modules self-contained and easy to import.
          '';
          hostConfig = {
            name = lib.removePrefix prefix name;
          };
        };
      in
      {
        name = lib.removePrefix prefix name;
        value = inputs.nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            module
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = specialArgs;
            }
          ];
        };
      }
    ))
  ];
}
