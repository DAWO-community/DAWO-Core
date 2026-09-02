{
  # The handbook (docs/handbook) as a build output: `nix build .#handbook`
  # renders the site, and `nix run .#handbook-serve` previews it locally.
  #
  # mdBook bundles its own CSS, JS and search index, so the rendered site pulls
  # nothing from a CDN at runtime. That is deliberate and worth keeping: a
  # documentation site for a sovereign workplace should not need somebody
  # else's infrastructure to render.
  #
  # The pages under docs/handbook/src mostly {{#include}} the documentation
  # that already lives in the repository, so a page and the code it describes
  # move together instead of drifting into two versions of the same claim.
  perSystem =
    { pkgs, ... }:
    {
      packages.handbook = pkgs.stdenvNoCC.mkDerivation {
        name = "dawo-handbook";
        src = ../../.;
        nativeBuildInputs = [ pkgs.mdbook ];
        buildPhase = ''
          runHook preBuild
          mdbook build docs/handbook
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          cp -r docs/handbook/book "$out"
          runHook postInstall
        '';
      };

      apps.handbook-serve = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "dawo-handbook-serve" ''
            exec ${pkgs.mdbook}/bin/mdbook serve --open docs/handbook
          ''
        );
      };
    };
}
