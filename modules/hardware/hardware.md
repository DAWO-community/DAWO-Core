# Hardware

Per-device hardware support for the DAWO fleet, layered:

- `hardware-dawo-base` (dawo-base.nix) - the generic baseline every laptop gets
  (via profiles-dawo-generic): redistributable firmware, fwupd, bluetooth,
  initrd-systemd, platform. No model specifics.
- A per-model module (e.g. lenovo-t495s.nix, hp-elitebook-850-g7.nix) adds only
  that model's quirks on top: a nixos-hardware profile, model initrd modules,
  CPU/GPU bits the profile does not cover.

## Adding a device (pick / look up / make)

1. **Pick (known):** if the model is in nixos-hardware, import its profile:
   ```nix
   imports = [ inputs.nixos-hardware.nixosModules.<device> ];
   # e.g. lenovo-thinkpad-t495, dell-latitude-..., framework-13-...
   ```
   If there is no exact-model profile, compose the `common-*` profiles
   (common-cpu-intel/amd, common-gpu-*, common-pc-laptop, common-pc-ssd), as the
   HP EliteBook module does.

2. **Look up:** the nixos-hardware README/flake lists every supported device and
   its module name - search there: https://github.com/NixOS/nixos-hardware

3. **Make (unknown):** no profile and no good `common-*` fit -> let nixos-facter
   detect the hardware at install time, no hand-written module:
   ```
   nixos-anywhere --flake .#<host> \
     --generate-hardware-config nixos-facter ./hosts/<name>-facter.json \
     --target-host root@<ip>
   ```
   (nixos-facter-modules is already a flake input.) Optionally write a thin model
   module and contribute the profile upstream to nixos-hardware.

Every path sits on top of `hardware-dawo-base`, so a new device needs little or
no hand-written hardware code - which is what makes netboot/fleet imaging of
arbitrary models practical.
