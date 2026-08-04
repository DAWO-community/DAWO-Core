# Changelog

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
