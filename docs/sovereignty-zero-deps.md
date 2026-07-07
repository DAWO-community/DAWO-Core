# Zero external dependencies — Dutch digital autonomy

Goal: **nothing fetched from foreign-controlled hosts at build or update time.**
Everything comes from NL-controlled infrastructure (`code.overheid.nl` + a self-
hosted NL binary cache). The upstream projects stay FOSS — we *mirror* them, we
don't rewrite them. Repo *hosting* is already sovereign; the *supply chain* is the
remaining exposure.

## Current exposure (audit)
- **15 flake inputs**, all `github.com`-hosted (all FOSS). See flake.nix.
- **1 build-time fetch**: the `libfprint-CS9711` fork (`modules/flake-parts/nixpkgs.nix`).
- **Binary caches**: `cache.nixos.org` + `nix-community.cachix.org` (US) trusted at
  build (`modules/nixos/nix-settings.nix`).
- **Flathub** (if flatpak apps are added; list currently empty).
- **Mutable refs**: nixpkgs-unstable, `disko/latest`, `nixos-hardware/master`,
  `comin/main`, `nix-flatpak?ref=latest` — float on upstream, pinned only by flake.lock.

## Target architecture
```
upstream github  --(mirror-sync CI, one controlled point, reviewed)-->  code.overheid.nl mirrors
                                                                              |
   fleet devices / builders  <--- git inputs (pinned rev) + NL binary cache <-+
```
Devices and builders touch ONLY `code.overheid.nl` (source) and the NL cache
(binaries). Foreign github is contacted solely by the mirror-sync job.

## Plan (phased)

### Phase 1 — Pin everything to revs (no infra, immediate)
Replace every mutable `?ref=latest|master|main|nixos-unstable` with a pinned
`?rev=<sha>`. Reproducible + no surprise upstream drift; updates become deliberate.
Small, low-risk, do first.

### Phase 2 — Mirror source inputs to code.overheid.nl (the big lift)
Per input: a mirror repo `code.overheid.nl/<org>/mirror-<name>`, synced from
upstream. Repoint flake.nix -> `git+https://code.overheid.nl/.../mirror-<name>?rev=<sha>`.
- **nixpkgs** is the heavy one (multi-GB) — a full git mirror on code.overheid.
- Include the `libfprint-CS9711` fork.
- One-time: mirror + repin; verify each host drvPath is identical (as with the
  dead-input prune, nix-diff should show only the flake-rev string).

### Phase 3 — Self-hosted NL binary cache (drop foreign substituters)
- Stand up harmonia/attic on NL infra (the inspoelstraat already runs harmonia;
  scale it or a dedicated NL server). Populate it by building from the mirrors.
- `nix.settings.substituters` = the NL cache ONLY; drop `cache.nixos.org` +
  `cachix`. Fallback = build-from-(mirrored)-source.
- Removes the last foreign build-time fetch.

### Phase 4 — Sovereign update process (mirror-sync CI)
A CI job on a NL runner (the inspoelstraat), weekly: pull upstream into the
code.overheid mirrors -> build against them -> populate the NL cache -> open a
repin-PR for human review. The fleet never touches github; the sync job is the one
reviewed choke point.

### Phase 5 — FOSS-swap the unfree/foreign runtime bits (where possible)
- `corefonts` (Microsoft fonts) -> metric-compatible FOSS (liberation / carlito).
- `allowUnfree = true` -> narrow to only what's genuinely needed.
- Pinned-CVE packages (electron, libxml2 for Horizon) -> upstream, ride the mirror.

## Honest residuals (out of DAWO's control)
- **Omnissa Horizon VDI + Microsoft Entra login** = the *client's* US-proprietary
  stack, at runtime. The Linux base is sovereign; the workload the user does is not.
  Document as a residual, don't imply it away. FOSS alternative = a sovereign VDI/
  desktop, a separate programme.
- The FOSS projects are *developed* on foreign github. Mirroring gives us the code
  + the ability to fork/self-maintain if upstream disappears — that is the real
  autonomy guarantee, not the illusion that no foreign code exists.

## Effort / order of attack
1. Phase 1 (pins) — hours, no infra. Do now.
2. Phase 5 corefonts swap — small.
3. Phase 3 NL cache — medium (infra), high sovereignty payoff.
4. Phase 2 mirrors — large (nixpkgs mirror), the core of the goal.
5. Phase 4 sync CI — medium, makes it sustainable.
