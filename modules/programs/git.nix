{
  flake.modules.nixos.programs-git =
    { pkgs, ... }:
    {
      programs = {
        git = {
          enable = true;
          lfs = {
            enable = true;
          };
          prompt = {
            enable = false;
          };
        };
      };
      environment.systemPackages = with pkgs; [
        git
      ];
    };
}
