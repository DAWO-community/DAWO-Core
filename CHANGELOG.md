# Changelog

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
