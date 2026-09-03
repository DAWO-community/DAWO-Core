{
  # SBOM and vulnerability reporting, as apps rather than packages.
  #
  # modules/flake-parts/handbook.nix can be a derivation because mdBook renders
  # a directory and needs nothing else. These cannot: sbomnix reads the live Nix
  # store, and the scanners fetch their vulnerability databases over the
  # network. A sandboxed build has neither, so `nix run` is the honest shape.
  #
  # What CI runs is exactly what a person can run, which is the point: the
  # published artefact has to be reproducible by whoever doubts it.
  perSystem =
    { pkgs, ... }:
    {
      apps.sbom = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "dawo-sbom" ''
            set -euo pipefail
            host="''${1:?usage: sbom <host> <outdir> [flake]}"
            outdir="''${2:?usage: sbom <host> <outdir> [flake]}"
            flake="''${3:-.}"
            mkdir -p "$outdir"

            # --buildtime walks the derivation graph and never realises the
            # toplevel, so this costs seconds rather than a full closure build.
            # It reports more than ships, because a build tool is in the graph
            # and not on the device; the runtime answer needs a built closure
            # and belongs to a release build, not to every merge.
            #
            # A flakeref target rather than a store path, because sbomnix only
            # joins nixpkgs metadata (licences, CPEs) for a flakeref.
            exec ${pkgs.sbomnix}/bin/sbomnix \
              "$flake#nixosConfigurations.$host.config.system.build.toplevel" \
              --buildtime \
              --csv "$outdir/sbom.csv" \
              --cdx "$outdir/sbom.cdx.json" \
              --spdx "$outdir/sbom.spdx.json"
          ''
        );
      };

      apps.vulnscan = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "dawo-vulnscan" ''
            set -euo pipefail
            sbom="''${1:?usage: vulnscan <sbom.cdx.json> <outdir>}"
            outdir="''${2:?usage: vulnscan <sbom.cdx.json> <outdir>}"
            mkdir -p "$outdir"
            export PATH=${
              pkgs.lib.makeBinPath [
                pkgs.grype
                pkgs.vulnix
              ]
            }:$PATH

            # Reads the CycloneDX file the sbom app already wrote instead of
            # walking the graph again. Reports; never a gate. A desktop closure
            # carries thousands of components and glibc, openssl and perl always
            # have an open CVE somewhere, so failing on any finding would leave
            # this permanently red, and a check that is always red is a check
            # nobody reads.
            exec ${pkgs.sbomnix}/bin/vulnxscan "$sbom" --sbom -o "$outdir/vulns.csv"
          ''
        );
      };
    };
}
