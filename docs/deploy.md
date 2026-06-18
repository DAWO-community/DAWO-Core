# Uitrol & beheer

Twee fasen: **initiële install** (kaal toestel → DAWO) met nixos-anywhere, en
**updates** van een draaiend toestel met deploy-rs (al gewired).

## 1. Initiële install — nixos-anywhere

Gebruikt de `disko`-layout van de host (partitioneert + versleutelt + installeert
op afstand). Geen extra flake-input nodig.

Voorwaarden: target boot in een Linux met SSH als root (installer-ISO of
NixOS-live), netwerk, en de host bestaat in de flake (bv. `dawo-t495s`).

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#dawo-t495s \
  --target-host root@<target-ip>
```

Hardware: de host heeft nu een handgeschreven hardware-module
(`modules/hardware/<machine>.nix`). Voor een nieuw modeltype kun je het profiel
op het toestel genereren:

```bash
nixos-anywhere --flake .#<host> --generate-hardware-config \
  nixos-facter ./modules/hardware/<machine>-facter.json root@<ip>
```

en die in de hardware-module importeren (`nixos-facter-modules` is al als input
aanwezig).

> LUKS: `disko-single-nvme-luks` gebruikt een `passwordFile` voor de geautoma-
> tiseerde install. Zet daarna een echte unlock (TPM2/FIDO2 via
> `systemd-cryptenroll`) of een interactieve passphrase.

## 2. Updates — deploy-rs

Elke host in de flake is automatisch een deploy-node (zie
`modules/flake-parts/deploy.nix`), via de `deploy`-user (SSH-key).

```bash
nix develop          # levert deploy-rs in de shell
deploy .#dawo-t495s  # bouwt en activeert op afstand
```

## 3. Vloot

Per toestel één host-bestand (`modules/hosts/clients/<naam>.nix`) dat een
profiel + hardware + disko + de juiste users importeert (zie docs/users.md).
Installeren = nixos-anywhere; daarna updaten = deploy-rs (of `comin` pull, al
geconfigureerd voor git-gestuurde updates).
