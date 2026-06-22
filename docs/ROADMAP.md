# DAWO roadmap

North star: a 1.0 production government workplace image. The releases below build
toward it. The principle throughout: a lean, standards-coupled core, with
org-specific flavour in thin overlays, and secure-by-default everywhere it does
not break the user experience or risk locking the user out (those stay opt-in).

## 0.1 - Pilot baseline (active)

Goal: get users onto Linux laptops. A clean, minimal, loginable image, proven by
a headless network install, delivered to the first Zaanstad pilot (5x KDE + 1x
GNOME for comparison) by 1 July.

- Lean core: apps, shell and browser opt-in; the pilot hosts enable enough to be
  productive out of the box (office + comms + creative + media on).
- Reproducible install proven on real hardware (T495s and HP EliteBook).
- Per-model hardware support: a generic baseline plus a per-model module, or
  nixos-facter for unknown models (see hardware.md).
- Disk encryption (LUKS via disko), systemd-boot, the dawo user.

## 0.2 - Modularity + balanced hardening

Goal: a modular, hardened, identity-aware image; proposed to MinBZK.

- dawo.<block> tiers; secure-by-default / opt-out except UX-breakers (Secure
  Boot, usbControl, apparmor, pam-2fa stay opt-in).
- Compliance profiles (BIO-1/2, NCSC) as selectable tiers.
- Observability seams: osquery (opt-in), journald log-export. The shipper/SIEM
  is an org choice, not baked into the core.
- CA trust (PKIoverheid) and VPN capability blocks.
- User identity contract moving toward agenix-backed secrets.
- Foreign-software strategy (sovereignty): no unvetted vendor apps in core.

## 0.3 - Org integration + strong auth

Goal: the three-layer consumer model proven across orgs.

- Three layers: dawo-core -> org-group overlay (e.g. VNG) -> org-specific overlay
  (e.g. Zaanstad). The Zaanstad overlay carries Omnissa Horizon + F5/OpenConnect
  VDI access and vendor apps.
- Live SIEM / Fleet (osquery) + NetBird wiring via the consumer overlays.
- Secure Boot + TPM2 + FIDO2 disk-unlock, so nobody types a disk-encryption
  password. On-device key ceremony, recovery path ready.
- Declarative enrollment; remote re-install without a USB stick (netboot /
  maintenance-boot).

## 1.0 - Production

Goal: production-ready, validated, fleet-scale.

- BIO/NCSC compliance validated.
- Fleet-scale reproducible provisioning ("inspoelstraat").
- Multi-org overlays; upstreamed into MinBZK.
- CI + SBOM; docs complete.

## Cross-cutting tracks

These run across releases and land where the pilots and feasibility allow.

### User provisioning, RBAC and fleet management (0.2/0.3)

The target shape: each device has two users by default - a beheeraccount
(admin/wheel, local break-glass, users-as-code) and the person (end user,
SSO/SSSD-backed). RBAC: manage who has access to what, driven by identity and
groups (polkit/sudo policy). Fleet: centrally manage which users land on which
devices, plus updates and inventory. Builds on the existing line (admins
users-as-code, end users via SSO) and the fleet update mechanism (autoUpdate /
comin over NetBird, with Fleet/Wazuh for inventory and monitoring). Exact phasing
(0.2 vs 0.3) depends on pilot outcomes and feasibility.

### Test and update strategy (every release)

Each release is gated on testing what we have on real pilot hardware: boot,
login, disk unlock, USB, the app set, and - critically - the update path
(autoUpdate/comin pulls a new revision and the device rebuilds and switches
cleanly). A release is not deliverable until the update path is proven on device.

### Provisioning pipeline ("inspoelstraat")

Network install over wired PXE from an operator laptop, so machines are imaged
without a USB stick each. The netboot installer image lives in this flake; the
operator-side serving tooling lives in the separate dawo-netboot add-on repo.
Scales to fleet provisioning toward 1.0.
