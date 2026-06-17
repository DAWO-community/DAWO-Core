{ inputs, ... }:
{
  flake.modules.nixos.nixos-nix-settings =
    { pkgs, lib, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [
        "electron-39.8.10"
      ];

      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          auto-optimise-store = true;
          download-buffer-size = 524288000;
          substituters = [
            "https://cache.nixos.org?priority=10"
            "https://nix-community.cachix.org"
            "https://cache.nixos-cuda.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          ];
        };
        optimise = {
          automatic = true;
          dates = [ "12:00" ]; # Optional; allows customizing optimisation schedule
        };
        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 7d";
        };
        nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
      };
      programs.nix-ld = {
        enable = true;
        libraries = [ pkgs.markdownlint-cli ];
      };
    };
}
