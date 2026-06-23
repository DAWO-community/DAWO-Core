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
