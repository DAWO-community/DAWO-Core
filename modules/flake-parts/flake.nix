{ lib, ... }:
{
  options.flake.meta = lib.mkOption {
    type = with lib.types; lazyAttrsOf anything;
  };

  # Where this flake lives, for anything that reports provenance. It pointed at
  # a personal fork, which is the wrong answer to "where did this device's
  # configuration come from".
  config.flake.meta.uri = "https://codeberg.org/DAWO/DAWO-Core";
}
