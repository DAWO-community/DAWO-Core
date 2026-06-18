# Architecture

DAWO NixOS follows a modular, flake-based approach to infrastructure management. The codebase is designed to be dry (Don't Repeat Yourself) by leveraging the `modules` directory.

## Components
- **Flakes**: Definition of inputs (other repositories/overlays) and outputs (the final sets).
- **Modules**: Composable units of configuration in `/modules`.
- **Hosts**: Terminal definitions of how specific machines combine modules into a bootable system.
- **Disko**: Integrated storage management for persistent data layers.

## Data Flow
1. **Input Resolution**: `flake.nix` pulls in remote inputs and local files.
2. **Configuration Assembly**: Host definitions select specific modules from `/modules`.
3. **Build Pipeline**: The Nix build system resolves all dependencies and generates the final filesystem tree.
4. **Deployment**: Resulting configurations are applied to hardware (via `disko` or direct boot).

## Key Design Decisions
- **Modularity Over Monoliths**: Every logical component is a separate module in `/modules`. 
- **Flake Pinning**: Ensuring all dependencies are locked via flake pins for reproducible builds.
- **Disko Integration**: Decoupling storage management from the NixOS system config to allow better lifecycle control of disks.

## Architecture Decision Records (ADR)

Short records of decisions that shape the image. Each one lists the context, the
decision, and the main consequence. Newest on top.

### ADR-0001: Blocks architecture, core flake + consumer inputs
- Context (#6, #8): the image has obligations that must hold on every device and
  things that are a per-deployment choice. We need one place to carry the
  obligations and a clear way for an organisation to deviate.
- Decision: this repo is the upstream core. Each capability is a block exposed as
  `flake.modules.nixos.<name>`. A consumer flake takes the core as an input and
  composes blocks. The interface is `dawo.<block>.enable` plus
  `dawo.<block>.options.<...>` for tunables. Two tiers, expressed as aggregate
  profiles: `profiles-dawo-core` (mandatory) and `profiles-dawo-hardened` (opt-in).
- Consequence: branding, user profiles and app sets live in the consumer, not here.

### ADR-0002: mkForce for mandatory, mkDefault for suggested, no undefined options
- Context (#8): mandatory blocks must not be silently weakened, but tunables must
  stay configurable. Leaving an option undefined can break a device quietly.
- Decision: mandatory enforcement uses `lib.mkForce` (a host cannot silently lower
  the floor, and there is no escape hatch). Suggested defaults use `lib.mkDefault`.
  Where an empty or undefined option would break the device (for example an empty
  NTP server list), the block asserts at build time instead of failing silently.
- Consequence: a consumer configures core blocks through their `options`, but
  cannot disable them by accident.

### ADR-0003: Repo split, shared blocks plus per-organisation consumers
- Context (#8): more than one organisation will build on this. BZK and VNG both
  want their own workplace config without forking the core.
- Decision: `DAWO-NixOS` stays the upstream core/blocks. Per-organisation shared
  blocks live in their own repos (for example `DAWO-NixOS-BZK`, `DAWO-NixOS-VNG`).
  A concrete device config (for example `DAWO-Gem-Zaanstad`) consumes the core and
  the relevant organisation repo as inputs.
- Consequence: the core carries obligations centrally; organisations layer on top.

### ADR-0004: Pin nixpkgs to a stable release, with an unstable overlay
- Context (#11): tracking nixos-unstable causes unexplained drift between builds.
- Decision: pin `nixpkgs` to the stable channel and add a separate
  `nixpkgs-unstable` input exposed through an overlay (`pkgs.unstable.*`) so a
  single package can be pulled from unstable when a newer version is needed.
- Consequence: reproducible base, with a controlled escape for individual packages.

### ADR-0005: BTRFS as the standard disk layout
- Context (#14): an earlier ext4 layout was only there to match an existing
  in-place install. BTRFS avoids future inode limits and matches the base image.
- Decision: use the BTRFS `single-nvme-luks` disko profile as the standard layout
  for clients. A fresh install reuses it; the ext4 profile is removed.
- Consequence: one layout to maintain; clients reinstall onto BTRFS.

### ADR-0006: Track lanzaboote from master
- Context: lanzaboote v1.0.0 sets `boot.bootspec.enable`, which nixpkgs 26.05
  removed, so the pinned tag fails to evaluate on the current nixpkgs.
- Decision: track lanzaboote from master until a tagged release is compatible.
- Consequence: Secure Boot hosts evaluate again; revisit when a new tag lands.
