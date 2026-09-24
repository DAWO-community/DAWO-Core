# Inspoel-runbook — DAWO-NixOS image (MinBZK) op 15 laptops

Volledige, herhaalbare instructie om een batch laptops te imagen met de **generieke
MinBZK/DAWO-NixOS image** (dit platform: desktops, BIO/NCSC-hardening, printen/geluid/
scannen, LUKS + Secure Boot + TPM2-auto-unlock). Géén org-specifieke overlay — dit is de
kale DAWO-werkplek per hardware-model.

> **Scope:** dit is de generieke core-image. Named end-users, VDI/office-apps, NetBird-mesh
> en comin-auto-update zijn **overlay-config** (org-specifiek) en zitten hier NIET in. Wil je
> die → gebruik het overlay-imaging-pad, niet deze runbook.

> **GEEN secrets in dit bestand.** LUKS-passphrases + wachtwoorden staan in **Proton Pass
> (BB Open Ops)**. Repo mag publiek → nooit een geheim inplakken.

---

## 0. Waarom PXE via het station (client-isolation omzeilen)

Op locatie kan het netwerk **client-isolation** hebben (devices/hotspots zien elkaar niet).
Daarom imagen we via het **inspoelstraat-station** (MSI) op z'n **eigen provisioning-switch**
(`192.168.50.0/24`) — een dedicated switch isoleert niet, dus het station bereikt elke
installer. Alleen het station heeft internet nodig (binary cache); harmonia op het station
serveert de closures lokaal, dus na de eerste laptop is elke install snel.

---

## 1. Prerequisites (eenmalig, vóór de dag)

### 1a. Kies de core-host per hardware-model
De image = `nixosConfigurations.<host>` uit **DAWO-NixOS**. Bestaande hosts:
```
nix flake show /home/brambuijs/Cloud/Operations/dawo/DAWO-NixOS | grep -A20 nixosConfigurations
```
Typisch: `dawo-hp-probook-4g1i` (KDE) / `dawo-hp-probook-4g1i-gnome` (GNOME),
`dawo-hp-eb-850g7`, `dawo-t495s`. **Onbekend model** → eerst een hardware-block +
host in de core toevoegen en committen (zie `modules/hardware/` + `modules/hosts/clients/`).

### 1b. Versie / branch
Deploy de stabiele release-branch met de audit-fixes (printen/geluid/scannen/emoji,
autoUpgrade-uit): `release/0.1.0-install` (of de nieuwste geteste). Zet 0.1.2 pas live als
getest. Push alleen onder `bram.buijs`; MinBZK-main niet zonder expliciete go.

### 1c. Station gereed
- MSI-station up, op de provisioning-switch (`enp3s0 = 192.168.50.1`); dnsmasq/nginx/harmonia
  draaien (`inspoelstraat-appliance/`). Uplink (`enp2s0`) heeft internet.
- Netboot-artifacts vers: `inspoelstraat-appliance/refresh-netboot.sh`.
- Operator-SSH-key (`~/.ssh/bbuijs`) in de agent.

### 1d. LUKS-passphrases
Bedenk per device een unieke sterke passphrase → noteer in Proton Pass (BB Open Ops),
één item per laptop (koppel aan de asset-tag/sticker).

---

## 2. Op de dag — wire it

1. Provisioning-switch aan; station's `enp3s0` erin; laptops met **ethernet** aan dezelfde
   switch (USB-dongle waar geen onboard NIC).
2. Verifieer station: `192.168.50.1` up, `systemctl status dnsmasq nginx harmonia`.
3. Per laptop-BIOS: **Secure Boot UIT** (install-image is unsigned), **boot van netwerk/PXE**
   bovenaan. (SB gaat later per device weer aan, §5.)

---

## 3. PXE-boot + installer-IPs

1. Laptops aan → ze PXE-booten de DAWO-installer in RAM (sshd + operator-key). Batch kan.
2. Vind de installer-IPs op de prov-LAN:
   ```
   inspoelstraat/find-hps.sh          # of: nmap -p22 --open 192.168.50.0/24
   ```
   Koppel IP ↔ laptop via de MAC-sticker/asset-tag.

---

## 4. Installeren (per device, parallel)

Per laptop, vanaf het station (of Fedora-host op de prov-LAN):
```
inspoelstraat/install-hp.sh <installer-ip> <host>   # vraagt de passphrase, leest hem van stdin
# bv: inspoelstraat/install-hp.sh 192.168.50.55 dawo-hp-probook-4g1i '<luks-uit-PP>'
```
Dit draait `nixos-anywhere --flake DAWO-NixOS#<host> --phases disko,install` (Secure Boot uit),
zet de LUKS-passphrase, kopieert de closure van het station (harmonia-cache). Meerdere
terminals = parallel imagen.
- Klaar = "done". Herhaal voor alle 15 (noteer host ↔ asset-tag ↔ LUKS in PP).

---

> De passphrase hoort niet op de commandoregel: daar staat hij in `ps` en in de
> shellgeschiedenis van de operator. Het installatiescript zet hem op de target
> in `/run/dawo-luks.key`, mode 0600, op tmpfs. Zie
> `dawo.disk.luks.passwordFile` als een uitrol een ander pad wil.

## 5. Per device: reboot → verify → Secure Boot + TPM2

### 5a. Eerste boot
1. Reboot (van schijf, niet PXE). LUKS-prompt → device-passphrase (PP).
2. Login = **dawo/dawo** bootstrap-admin (generieke image; wijzig het wachtwoord bij
   uitlevering of via de overlay als die later komt).

### 5b. Secure Boot + TPM2 (basis-hardening) — bewezen ceremonie
> Volgorde kritiek: TPM2 PCR7 meet de SB-staat, dus **TPM2 ná SB**.
1. **on-device** (of `deploy@<ip>` op de prov-LAN): `sudo sbctl create-keys` → switch naar de
   **SB-variant** van de host (lanzaboote, signt de UKI) → `sudo sbctl enroll-keys --microsoft`
   (firmware in Setup Mode).
2. **BIOS**: Secure Boot = **Enabled** + reboot. (HP: evt. Sure Start-protection uit + keys
   clearen voor Setup Mode; AMI: PK deleten.)
3. **PAS DAN TPM2**:
   `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --unlock-key-file=<keyfile> /dev/disk/by-partlabel/disk-main-luks`
   (keyfile = passphrase **zonder newline**, `printf %s`; slot-0 blijft break-glass).
4. Reboot → moet **passphrase-loos** auto-unlocken. 1× emergency op de eerste SB-boot kan →
   nog eens rebooten.

---

## 6. Verificatie-checklist per device

- [ ] LUKS-auto-unlock werkt passphrase-loos (na TPM2)
- [ ] Secure Boot = enabled (`bootctl status | grep "Secure Boot"`)
- [ ] Login werkt
- [ ] **Printen** (CUPS actief, netwerk-printer vindbaar)
- [ ] **Geluid** (pipewire) + **emoji** rendert
- [ ] **Scannen** (SANE) beschikbaar
- [ ] Desktop (KDE/GNOME) OK

---

## 7. Recovery (vertel de gebruiker)

- Raar gedrag na update → **uit/aan**; bij start **SPACE** vasthouden → boot-menu → **vorige
  generatie**.
- Auto-unlock faalt (bv. firmware-wijziging → PCR7-mismatch) → **passphrase** (PP) ontsleutelt
  nog (slot-0 break-glass).

---

## 8. Geheimen (Proton Pass, BB Open Ops)

Per device: LUKS-passphrase (+ evt. host-key bij agenix-varianten). Nooit in deze repo.

---

## 9. Snelle referentie

```
# op de prov-switch:
inspoelstraat/find-hps.sh                                       # installer-IPs
inspoelstraat/install-hp.sh <ip> <host> <luks>                 # per device (parallel)
# per device na reboot: sbctl create-keys -> SB-variant switch -> enroll-keys -> BIOS SB on
#                        -> systemd-cryptenroll tpm2 pcrs=7 -> reboot (auto-unlock)
# checklist §6 -> uitleveren
```
