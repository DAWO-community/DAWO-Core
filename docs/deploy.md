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
