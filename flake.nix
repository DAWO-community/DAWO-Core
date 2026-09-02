{
  inputs = {
    # NOTE (sovereignty roadmap): all inputs below are FOSS but currently fetched
    # from github.com. Goal = zero foreign-hosted deps (Dutch digital autonomy) by
    # mirroring these to code.overheid.nl and repinning. 10 dead inputs were pruned
    # (audit); these 15 are load-bearing and next up for the mirror pass.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    # nix-maid moved to Codeberg; the GitHub mirror stops working on
    # 31 October 2026, and upstream warns about it on every evaluation.
    nix-maid.url = "git+https://codeberg.org/viperML/nix-maid";
    # nix-maid resolves maid.kconfig.package through npins rather than a flake
    # input, so that fetch sits outside our lock and reaches the live network on
    # every eval. When viperML moved kconfig-declarative from GitHub to Codeberg
    # the old URL began to 404 and every device configuration here stopped
    # evaluating, with nothing in this repository having changed. Pin it here so
    # it is in flake.lock like everything else and an upstream move is a lock
    # bump rather than a fleet that cannot build.
    kconfig-declarative = {
      url = "git+https://codeberg.org/viperML/kconfig-declarative";
      flake = false;
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    import-tree.url = "github:vic/import-tree";
    make-shell.url = "github:nicknovitski/make-shell";
    comin = {
      url = "github:nlewo/comin/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      # master: v1.0.0 still sets boot.bootspec.enable, removed in nixpkgs 26.05.
      url = "github:nix-community/lanzaboote";
      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
