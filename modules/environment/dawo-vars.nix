{
  flake.modules.nixos.environment-dawo-vars = {
    environment.variables = {
      NIXOS_OZONE_WL = 1;
      NIX_REMOTE = "daemon";
    };
  };
}
