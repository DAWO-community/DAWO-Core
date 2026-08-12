# Hardware

Per-device hardware support for the DAWO fleet, layered:

- `hardware-dawo-base` (dawo-base.nix) - the generic baseline every laptop gets
  (via profiles-dawo-generic): redistributable firmware, fwupd, bluetooth,
  initrd-systemd, platform. No model specifics.
- A per-model module (e.g. lenovo-t495s.nix, hp-probook-4g1i.nix) adds only
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
   HP ProBook module does.

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

## Peripherals: DisplayLink docks

`dawo.displaylink.enable` (off) adds evdi and the DisplayLink Manager service.
Without it a DisplayLink dock drives exactly one external monitor: the further
outputs are DisplayLink's own, and nothing in a stock kernel speaks to them, so
the second screen stays dark rather than reporting a fault.

The driver is **non-redistributable**, so it is not in this repository and not
in cache.nixos.org. nixpkgs handles that with `requireFile`, which turns every
device's store into a place somebody has to put a file by hand - workable for
one laptop, not for a fleet.

So the location is configuration instead:

```nix
dawo.displaylink = {
  enable = true;
  driverUrl = "https://mirror.example.org/displaylink-620.zip";
};
```

An organisation's own mirror is the better answer for a fleet: one place to
serve it from, no EULA click per device, and it keeps working when the vendor
moves its download. The vendor's direct link works too, and a `file://` path
serves a one-off machine.

**The URL is not what is trusted - the hash is.** Whatever `driverUrl` points at
is checked against the hash nixpkgs expects for the version it packages, so a
mirror serving something else fails the build instead of shipping it to a fleet.
`driverHash` overrides that expectation and is normally left alone: leaving it
null means the pin moves with a nixpkgs bump rather than fixing this fleet to
whichever release was current when someone wrote a hash down.

Enabling the block without a `driverUrl` fails the evaluation with an assertion
that says so, rather than at build time with a `requireFile` message about a
file nobody was told to fetch.

The block appends `displaylink` to `services.xserver.videoDrivers` rather than
replacing it. That option carries a default (`modesetting`, `fbdev`) and a
default is replaced by any definition rather than merged with it, so setting it
to `[ "displaylink" ]` would take `modesetting` away from the internal panel and
leave a laptop driving its dock and nothing else.
