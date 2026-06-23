# Secure Boot + TPM2 auto-unlock (on-device runbook)

Goal: turn on Secure Boot (lanzaboote-signed boot) and TPM2 auto-unlock of the
LUKS root, so the machine boots without anyone typing a disk passphrase - the UX
win for the pilot. The passphrase stays enrolled as break-glass.

Both ship in the image as opt-in blocks, OFF by default:
- `dawo.secureboot.enable` (boot-loader block)
- `dawo.diskUnlock.tpm2.enable` (boot-tpm2-unlock block)

This is a deliberate second step because a wrong enrolment can leave a machine
unbootable. Do it ON the device, with recovery ready. Order matters: Secure Boot
first (it defines PCR 7), then TPM2 enrol against PCR 7.

## Before you start (recovery)

- The LUKS passphrase is in Proton Pass (BB Open Ops). It keeps working as
  break-glass even after TPM2 enrolment.
- Have a recovery USB (the DAWO installer ISO) on hand. Worst case: boot it and
  unlock the disk with the passphrase.
- Take a backup / be ready to reinstall (pilot devices hold no real data yet).

## 1. Secure Boot (lanzaboote)

```bash
sudo sbctl create-keys                       # generate the signing keys
# set dawo.secureboot.enable = true; for this host, then:
sudo nixos-rebuild switch --flake <ref>#<host>
sudo sbctl enroll-keys --microsoft           # BIOS must be in Setup Mode first
```
Reboot, turn Secure Boot ON in firmware. Check it took:
```bash
bootctl status | grep -i 'secure boot'       # -> enabled
```

## 2. TPM2 auto-unlock (PCR 7 = Secure Boot state)

```bash
# set dawo.diskUnlock.tpm2.enable = true; for this host, then:
sudo nixos-rebuild switch --flake <ref>#<host>
# enrol the LUKS key into the TPM, bound to PCR 7:
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks
```
Reboot: the disk should unlock from the TPM, no passphrase prompt.

## Verify

- Reboot and confirm no passphrase is asked.
- `dawo-proof` shows Secure Boot active.
- The passphrase still works if you do ask for it (break-glass).

## If it goes wrong

- TPM2 unlock failing falls back to the passphrase prompt automatically (e.g.
  after a firmware update changes PCR 7) - just type it, then re-enrol.
- Cannot boot at all: boot the recovery USB, `cryptsetup open` with the
  passphrase, fix the config, rebuild.
- To undo TPM2: `sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/...` and set
  `dawo.diskUnlock.tpm2.enable = false;`.

## Remote / fleet method (proven on HP ProBook 4 G1i, 2026-06-24)

The whole ceremony can be driven remotely except the firmware steps. Push the
rebuilds as a **trusted-user** (the `deploy` user), or the target rejects the
unsigned, locally-built closure ("lacks a signature by a trusted key"):

```
# 1. on the device: create the sbctl keys (sbctl ships only once SB is enabled,
#    so bootstrap it):  sudo nix run nixpkgs#sbctl -- create-keys
# 2. from the operator: switch to the Secure-Boot host variant (signs the UKIs):
nixos-rebuild switch --flake .#<host>-sb --target-host deploy@<ip> --use-remote-sudo --fast
# 3. firmware in Setup Mode (see vendor note), then on the device:
sudo sbctl enroll-keys --microsoft
# 4. TPM2: enrol the LUKS key bound to PCR 7 (passphrase stays as slot 0):
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
  --unlock-key-file=<(printf %s '<passphrase>') /dev/disk/by-partlabel/disk-main-luks
# 5. reboot -> signed boot enforced + disk unlocks from the TPM, no passphrase.
```

Notes:
- Setup Mode on some vendors is locked (e.g. HP Sure Start "Secure Boot Keys
  Protection"); the BIOS specifics live in the consumer overlay runbook
  (Zaanstad: docs/hp-secureboot-bios.md).
- The enrolled TPM2 slot commits after the next reboot (sbctl status may still
  show "Setup Mode" immediately after enroll-keys; it flips on reboot).
- After a TPM unlock the network/sshd can take a minute; "no route to host" while
  polling is not a failed unlock — check the screen (no LUKS prompt = success).
- PCR 7 binding proved stable across generations on the ProBook 4 G1i.
