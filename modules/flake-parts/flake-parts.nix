{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  # Which systems the perSystem outputs are built for. Without this, flake-parts
  # iterates over nothing: `devShells`, `apps` and `packages` all evaluate to an
  # empty set, so `nix develop` - the shell docs/deploy.md tells an operator to
  # use for deploy-rs - fails with "does not provide attribute", while
  # `nix flake check` stays green, because the baseline check writes
  # flake.checks directly rather than going through perSystem.
  #
  # The images are x86_64 laptops. Add an architecture here when there is one to
  # build for, not before.
  systems = [ "x86_64-linux" ];
}
