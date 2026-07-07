{
  inputs = {
    # NOTE (sovereignty roadmap): all inputs below are FOSS but currently fetched
    # from github.com. Goal = zero foreign-hosted deps (Dutch digital autonomy) by
    # mirroring these to code.overheid.nl and repinning. 10 dead inputs were pruned
    # (audit); these 15 are load-bearing and next up for the mirror pass.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nix-maid.url = "github:viperML/nix-maid";
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
