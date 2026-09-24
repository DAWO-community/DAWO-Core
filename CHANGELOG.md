# Changelog

## Unreleased

## 0.1.3 - security scan, first round

The first half of the security scan of 3 September, plus what it took to make
main evaluate again. Issues #95 to #158. Everything that changes what a
consumer has to do waits for 0.2.0.

Security:

- fix(users): the deploy credential is out of the repository, sudo for the
  deploy account is scoped to deploy-rs's activation command, and the reason
  it stays a trusted user is written down (#102, #124)
- fix(users): `dawo.bootstrapUser.initialHashedPassword` takes a hash the
  deployment owns; the documented default still works and warns at every
  build (#104, #126)
- feat(hardening): account lockout (five attempts, ten minutes) and password
  quality (twelve characters, two classes) on every host. FIDO2 is wired but
  off (#108, #141)
- feat(hardening): the screen locks after five minutes on both desktops (#106,
  #145), and USB device control is opt-in at the hardened level rather than
  claimed as mandatory (#149)
- feat(hardening): `dawo.hardening` selects security controls per rule instead
  of per block: an ordered level (baseline, hardened, strict), a compliance
  selection that cuts across it, and a switch per rule that wins over both. The
  register also produces `dawo-verify`, which says on the device whether each
  enabled rule holds and why each disabled one is off (#110, #137). The first seven
  rules carry checks only; configuration moves over one subject at a time.
- fix(systemd): the two units this repository defines run with a read-only
  system and only the capabilities they use (#113, #139)
- docs: the mandatory tier lists the three blocks it delivers, not five (#109,
  #150)

Fixes:

- fix(maid): kconfig-declarative is pinned in our own lock; main did not
  evaluate while its upstream URL returned 404 (#97, #98)
- fix(flake): the flake declares its systems, so `nix develop` works (#134,
  #156)
- feat(auto-update): comin takes a credential, so a private overlay updates
  (#95, #99)
- fix(hardware): DisplayLink starts its manager and loads evdi under Wayland,
  not only under X11 (#96, #100)
- feat(update): `dawo-update-status` on every device - service state, last
  poll, last generation and whether a reboot is pending, without sudo. Reads
  comin's own socket where it answers and systemd plus the system profile
  where it does not, so it still reports on a device whose update loop is
  what broke. Desktop notifications are available opt-in through
  `dawo.autoUpdate.desktopNotifications.enable` (#133, #135).
- fix(plasma): the wallet unlocks at the graphical login (#107, #143)
- refactor(maid): the Plasma panel is generated, and GNOME hosts no longer carry
  it (#154)
- fix(version): the release a device reports is read from the newest heading
  in this file. It was a literal, and 0.1.3 shipped saying 0.1.2
- fix(meta): `flake.meta.uri` points at this repository, not a personal fork
  (#152)

CI and upkeep:

- feat(ci): `nix flake check` and an eval of every host on every push (#101,
  #128), and an SBOM per host with a vulnerability report on main (#151, #158).
  The report step itself ran with a flag vulnxscan does not have and failed on
  every run until the fix in this release
- chore(ci): the tree is formatted and linted with treefmt, statix and deadnix
  (#140)
- chore(deps): all inputs updated, nix-maid followed to Codeberg, and two more
  inputs follow our nixpkgs (#63, #129, #138)
- docs: a handbook (#130), three ADRs (#132), and the traps that cost hours
  this round (#155)
- chore(git): union merges for CHANGELOG.md and architecture.md (#157)

## 0.1.2 - the move, and the vulnerability backlog

First release from Codeberg. Issues #55 to #80.

- chore(migration): the fleet and the docs point at Codeberg (#80). Devices
  imaged before the move, with no explicit repoUrl, must be repointed by hand
  once - the fix cannot reach them from the address it replaces.
- feat(printing): `drivers` names a set (`open` / `broad`) instead of taking a
  package list, discovery is separable, and the printer GUI is installed only
  where the desktop lacks one (#76)
- chore(deps): all fifteen flake inputs updated; openssl 3.6.3, expat 2.8.2,
  python 3.13.14, and 7.1.7 on the hosts that follow the latest kernel
  (#62, #71, #72, #74)
- feat(firefox): hunspell spell check dictionaries, and `dawo.firefox.dictionaries`
  to choose which of the eleven a device carries - 26 MB for all of them, 3.0 MB
  for two (#55)

Three vulnerability findings were closed as not applicable rather than fixed,
each with the evidence on the issue: ejs (#67) and simple-git (#69) are not in
the closure at all, and the ffmpeg finding (#73) matched an NVD range of the
form *before 8.1* against `ffmpeg_7` 7.1.5, which already carries the fix
backported to 7.1.4. That shape of finding over-reports against maintained
stable branches and needs a check against the distribution trackers before it
becomes an issue.

## 0.1.1 - audit fixes

Fixes from the first real use of 0.1.0. Issues #35 to #44.

- feat(audio): PipeWire in the core baseline - GNOME hosts had no sound (#35)
- feat(fonts): Noto Color Emoji - tofu boxes in chat and on the web (#36)
- feat(scanning): SANE in the core baseline (#37)
- feat(printing): opt-in CUPS + mDNS printing block (#38)
- fix(update): system.autoUpgrade off; comin is the single update source (#39)
- feat(hardware): NTFS support and zram swap in the base (#40)
- fix(ssh): key-only auth fleet-wide, password login disabled (#41)
- chore(deps): drop 10 dead flake inputs, 25 -> 15 (#42)
- test(checks): coverage gate on the workplace baseline (#43)
- feat(plasma): Tokodon behind dawo.desktop.plasma.socialClient (#44)

Also: a zero-external-dependencies sovereignty plan, an imaging runbook in
docs/, and two flake.lock bumps.

## 0.1.0 - pilot baseline

First tagged DAWO release: the baseline image for the first pilot.

- Lean core with opt-in apps, shell and browser; pilot hosts enable office,
  comms, creative and media so they are productive out of the box.
- Reproducible network install proven on real hardware (ThinkPad T495s and HP
  EliteBook 850 G7).
- Per-model hardware support: a generic baseline plus per-model modules, or
  nixos-facter for unknown models (see modules/hardware/hardware.md).
- Disk encryption (LUKS via disko); GNOME or KDE Plasma, one per host.
- On-device proof: dawo-proof reports the release (0.1.0) next to the exact
  flake revision, so support can read off both per device.

Earlier 0.1.x numbers were never tagged, so the first real release starts at
0.1.0.
