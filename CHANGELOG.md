# Changelog

## Unreleased

- feat(update): `dawo-update-status` on every device - service state, last
  poll, last generation and whether a reboot is pending, without sudo. Reads
  comin's own socket where it answers and systemd plus the system profile
  where it does not, so it still reports on a device whose update loop is
  what broke. Desktop notifications are available opt-in through
  `dawo.autoUpdate.desktopNotifications.enable`.
- feat(hardening): `dawo.hardening` selects security controls per rule instead
  of per block: an ordered level (baseline, hardened, strict), a compliance
  selection that cuts across it, and a switch per rule that wins over both. The
  register also produces `dawo-verify`, which says on the device whether each
  enabled rule holds and why each disabled one is off (#110). The first seven
  rules carry checks only; configuration moves over one subject at a time.
- feat(localization): `dawo.localization` replaces the two hard-wired locale
  modules. The system language and the regional formats are now separate
  options, the ten most spoken languages in Europe plus Dutch are generated on
  the device so a user can switch the desktop language without a rebuild, and
  each offered language gets its spell checker (#56). Consumers importing
  `localization-nl_nl` or `localization-en_nl` switch to `localization-languages`;
  the defaults reproduce the old Dutch behaviour. The legacy `nl_NL/ISO-8859-1`
  locale is no longer generated.

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
