{
  inputs,
  withSystem,
  ...
}:
{
  imports = [
  ];

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfreePredicate = _pkg: true;
        };
        overlays = [
          # Libfprint for USB Reader
          (final: prev: {
            libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
              version = "git";
              src = final.fetchFromGitHub {
                owner = "ericlinagora";
                repo = "libfprint-CS9711";
                rev = "c242a40fcc51aec5b57d877bdf3edfe8cb4883fd";
                sha256 = "sha256-WFq8sNitwhOOS3eO8V35EMs+FA73pbILRP0JoW/UR80=";
              };
              nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
                final.opencv
                final.cmake
                final.doctest
              ];
            });
          })
          (final: _prev: {
            stable = import inputs.nixpkgs-stable {
              inherit (final) config;
              inherit system;
            };
          })
          (final: _prev: {
            # Pull a single package from unstable when a newer version is needed:
            #   environment.systemPackages = [ pkgs.unstable.<name> ];
            unstable = import inputs.nixpkgs-unstable {
              inherit (final) config;
              inherit system;
            };
          })
        ];
      };
    };

  flake = {
    overlays.default = _final: prev: {
      local = withSystem prev.stdenv.hostPlatform.system ({ config, ... }: config.packages);
    };
  };
}
