{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  # `nix fmt` formats the tree, and `nix flake check` fails when it is not
  # formatted. Three tools, each earning its place:
  #
  # nixfmt   - one style, decided by a tool, so review is about the change.
  # statix   - real footguns in a codebase this dense with mkIf, mkMerge and
  #            mkForce, and it fixes what it finds rather than only complaining.
  # deadnix  - bindings left behind by a refactor. Nothing to report today,
  #            which is the point of adding it before that changes.
  perSystem = {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
      };
    };
  };
}
