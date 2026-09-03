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

## Modular design: blocks, tiers and consumers

The core repo (this one) is a library of blocks, not a finished image. Each
capability is a block exposed as `flake.modules.nixos.<name>`, with a uniform
interface so a consumer can compose them without reading the implementation:

- `dawo.<block>.enable` turns the block on (a `mkEnableOption`).
- `dawo.<block>.<tunable>` holds the settings; the body lives in
  `mkIf cfg.enable`.

Enforcement follows one rule (ADR-0002): mandatory security settings are forced
with `lib.mkForce` so a consumer cannot silently weaken them, suggested defaults
use `lib.mkDefault`, and an option that would break a device if left empty (an
empty NTP list, a non-positive login-attempt limit) asserts at build time instead
of failing quietly.

Blocks are grouped into two tier-aggregates a consumer imports:

- `profiles-dawo-core` -- the mandatory baseline that is actually delivered:
  ssh, sysctl and chrony, plus the login policy (PAM). Forced on; a consumer
  configures those blocks through their options but cannot drop one. Wired into
  `profiles-dawo-generic`.
- `profiles-dawo-hardened` -- opt-in blocks that cost the user something or are
  not ready: AppArmor, and the GNOME lockdown. Importing it only declares the
  options.

Two things this list used to claim and did not deliver, corrected here rather
than left as a comment that reads better than the code. **usbguard** is opt-in,
on purpose: a device that refuses a USB stick out of the box reads as broken to
the person holding it, so it is selected at the hardened level or per rule, not
forced. **auditd** is deferred: the module is a no-op on nixpkgs 26.05 because
of an upstream auditctl bug, so claiming it here only faked coverage. journald
is the log base until that is fixed.

New controls arrive as rules in the register rather than as blocks; see
ADR-0010.

The consumer model has three layers (ADR-0001, ADR-0003):

1. `DAWO-NixOS` (this repo) -- the upstream core: blocks plus the two tiers. No
   branding, no user accounts, no app sets.
2. Per-organisation repos (for example `DAWO-NixOS-BZK`, `DAWO-NixOS-VNG`) take
   the core as a flake input and add their own shared blocks.
3. A concrete device config (for example `DAWO-Gem-Zaanstad`) consumes the core
   and the relevant organisation repo, and pins a host to its hardware and disko.

This keeps the obligations in one place and lets organisations layer their own
choices on top without forking the core.

## Architecture Decision Records (ADR)

Short records of decisions that shape the image. Each one lists the context, the
decision, and the main consequence, oldest first, so a reader can follow how the
image got to where it is.

### ADR-0001: Blocks architecture, core flake + consumer inputs
- Context (#6, #8): the image has obligations that must hold on every device and
  things that are a per-deployment choice. We need one place to carry the
  obligations and a clear way for an organisation to deviate.
- Decision: this repo is the upstream core. Each capability is a block exposed as
  `flake.modules.nixos.<name>`. A consumer flake takes the core as an input and
  composes blocks. The interface is `dawo.<block>.enable` plus
  `dawo.<block>.<tunable>` for settings. Two tiers, expressed as aggregate
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

### ADR-0007: Nothing evaluates over the network except through flake.lock
- Context (#97): every device configuration stopped evaluating, with nothing in
  this repository having changed. nix-maid resolves `maid.kconfig.package`
  through npins rather than a flake input, so that fetch sat outside our lock and
  reached the live network on every evaluation. When the upstream repository
  moved from GitHub to Codeberg the old URL began to 404, and the core every
  managed device is built from could not be evaluated at all.
- Decision: a dependency an evaluation reaches for is a flake input, pinned in
  `flake.lock`, or it does not exist. Where an upstream resolves something
  through its own pinning mechanism, we take that dependency into our lock and
  pass it in explicitly rather than letting the default reach out.
- Consequence: an upstream moving house is a lock bump somebody reviews, not a
  fleet that cannot build. The cost is that such an input has to be noticed and
  adopted by hand; the check that notices it is CI evaluating every host
  configuration rather than a subset (#88).

### ADR-0008: The handbook is generated from the documentation in the repository
- Context (#1): documentation was a flat set of files plus a page per module
  directory, with no index and no order, so a reader could not tell where to
  start or what existed. A separate documentation site would answer that, and
  would immediately start drifting from the code it describes.
- Decision: the handbook lives in `docs/handbook` as an mdBook whose pages
  mostly `{{#include}}` the documentation already in the tree. New prose is
  written only for questions no file answers. It builds with
  `nix build .#handbook`, and mdBook bundles its own assets, so the rendered site
  fetches nothing from anybody else's infrastructure.
- Consequence: one source of truth per claim, and a page cannot silently
  contradict the code. In exchange the book inherits its structure from the
  repository layout, so a badly placed document is a badly placed chapter.

### ADR-0009: Language and regional formats are two settings, not one
- Context (#56): the image carried two localization modules that differed by a
  single line, and the language a device was imaged with could not be changed
  without an operator and a rebuild.
- Decision: `dawo.localization` splits the language the desktop is written in
  from the conventions used for dates, numbers, currency and paper, and generates
  every offered locale on the device. Changing the desktop language is a user
  action in Plasma or GNOME, not a rebuild.
- Consequence: an English-language desktop in the Netherlands still writes
  Dutch dates, and a device serves a user whose language is not the one the
  deployment was built around. The price is disk: every offered locale is
  generated whether or not anybody selects it.

### ADR-0010: hardening is a register of rules, not a set of blocks
- Context (#110, and #106 and #114 as the evidence): controls were grouped into
  two import lists. Whether a control applied could only be answered by reading
  code, and that is how a whole tier came to be imported by nobody without
  anything noticing, and how the on-device evidence script came to check for
  controls no host runs. A deployment that wanted nineteen of twenty rules had
  to take the block or rebuild it.
- Decision: the unit is a rule. Each rule is data in `flake.dawo.rules` carrying
  its own configuration, its own check, and its metadata: severity, tags, the
  norms that ask for it, and why it exists. Selection has two axes.
  `dawo.hardening.level` is ordered (baseline, hardened, strict) and a rule joins
  when its severity fits inside the level; `dawo.hardening.compliance` cuts
  across it, because a norm asks for a set of rules rather than a degree of
  strictness. A per-rule switch overrides both, in either direction.
- Consequence: the simple path stays one line, the fine grained path stops
  needing a fork, and the coverage check and the device evidence can be
  generated from the same source as the configuration rather than maintained
  beside it. The cost is that every hardening change now arrives as a rule with
  a check attached, which is more work per change and the reason the claim
  becomes provable.
