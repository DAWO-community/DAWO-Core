{
  flake.modules.nixos.programs-chromium = {
    programs.chromium = {
      enable = true;
      enablePlasmaBrowserIntegration = true;
    };
  };
}
