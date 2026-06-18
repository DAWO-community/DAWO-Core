# Deployment and management

Two phases: an initial install (bare device to DAWO) with nixos-anywhere, and
updates of a running device with deploy-rs (already wired).

## 1. Initial install - nixos-anywhere

Uses the host's disko layout (partitions, encrypts and installs remotely). No
extra flake input needed.

Requirements: the target boots into a Linux with SSH as root (installer ISO or
NixOS live), has network, and the host exists in the flake (e.g. dawo-t495s).

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#dawo-t495s \
  --target-host root@<target-ip>
```

Hardware: the host has a hand-written hardware module
(modules/hardware/<machine>.nix). For a new model type you can generate the
profile on the device:

```bash
nixos-anywhere --flake .#<host> --generate-hardware-config \
  nixos-facter ./modules/hardware/<machine>-facter.json root@<ip>
```

and import it in the hardware module (nixos-facter-modules is already an input).

> LUKS: disko-single-nvme-luks uses a passwordFile for the automated install.
> Afterwards set a real unlock (TPM2/FIDO2 via systemd-cryptenroll) or an
> interactive passphrase.

## 2. Updates - deploy-rs

Every host in the flake is automatically a deploy node (see
modules/flake-parts/deploy.nix), via the deploy user (SSH key).

```bash
nix develop          # provides deploy-rs in the shell
deploy .#dawo-t495s  # builds and activates remotely
```

## 3. Fleet

One host file per device (modules/hosts/clients/<name>.nix) that imports a
profile, hardware, disko and the right users (see docs/users.md). Installing is
nixos-anywhere; updating afterwards is deploy-rs (or a comin pull, already
configured for git-driven updates).

## 4. Secure Boot (opt-in, lanzaboote)

Devices boot with plain systemd-boot by default. Secure Boot is opt-in via
`dawo.secureboot.enable` and needs a one-time key ceremony on the device BEFORE
the flag is flipped - enabling it without enrolled keys leaves the device
unbootable (lanzaboote signs the boot entry against keys that are not there).

Order matters. On the running device:

```bash
# 1. create the sbctl key bundle (default pkiBundle: /var/lib/sbctl)
sudo sbctl create-keys

# 2. in the firmware, put Secure Boot into Setup Mode (clear the existing keys),
#    then enroll. Keep the Microsoft keys so firmware and option ROMs still load:
sudo sbctl enroll-keys --microsoft

# 3. enable Secure Boot in the host (dawo.secureboot.enable = true) and rebuild;
#    lanzaboote signs the UKIs and installs them to the ESP:
sudo nixos-rebuild switch --flake .#<host>

# 4. verify the boot files are signed, reboot, then turn Secure Boot back on in
#    the firmware:
sudo sbctl verify
sudo bootctl status        # expect "Secure Boot: enabled" after the reboot
```

Roll back: set `dawo.secureboot.enable = false` and rebuild to return to
systemd-boot.

> NEEDS IMPROVING. This is a manual, device-by-device ceremony and the most
> brittle step of a fresh install - a wrong order bricks the boot entry. Targets
> for automation: generate and enroll the sbctl keys during nixos-anywhere (or a
> first-boot activation unit) so a device comes up signed, and move LUKS unlock to
> TPM2-measured boot once keys are machine-bound. Tracked as a known limitation.
