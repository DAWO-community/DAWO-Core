{
  config,
  ...
}:
{
  flake.modules.nixos."hosts/dawo-t495s" =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        # Boot — lanzaboote (Secure Boot); pkiBundle /var/lib/sbctl matcht de
        # reeds geenrollde keys op de T495s -> in-place migratie zonder wipe.
        boot-secureboot
        boot-plymouth-bzk

        # Disko — ext4 "cryptroot"-layout die de bestaande install matcht
        # (no-wipe). Verse install van een ander toestel = disko-single-nvme-luks.
        disko-nvme-luks-ext4

        # Hardware
        hardware-lenovo-t495s

        # Profiles
        profiles-dawo-generic

        # Userland
        maid-dawo-generic

        # --- OPTIONEEL: uitcommentaar = aan (zie docs/modules.md) ---
        # Hardening (alles opt-in, niks auto-aan):
        # boot-hardening         # memory-hardening kernelParams (reboot nodig)
        # nixos-hardening        # sysctl + sudo wheel-only + tmp-mounts + banner
        # services-usbguard      # USB block-new; VEREIST allowlist, anders USB/tether dood
        # services-openssh       # SSH strak (no root, modern crypto)
        # services-journald      # persistente logs (bron, geen shipper)
        # services-chrony        # NL-NTP (betrouwbare tijd)
        # Specialer / gevoeliger:
        # services-pcscd         # PKIoverheid/Rijkspas-smartcard + FIDO2 (laag risico)
        # nixos-pki-overheid     # Firefox enterprise-roots; certs in host (laag risico)
        # networking-dns-tls     # DNS-over-TLS opportunistic (laag risico)
        # networking-egress-deny # egress default-deny (NU no-op; allowlist nodig)
        # nixos-apparmor         # MAC; canary testen (kan app-sandbox raken)
        # nixos-pam-u2f          # FIDO2-login/sudo; LOCKOUT-risk, eerst canary
        # nixos-pam-oath         # TOTP-2FA; LOCKOUT-risk, secret per user nodig
        # users-hardened         # mutableUsers=false (gitops); LOCKOUT-risk, zie docs/users.md
      ];
      networking.hostName = "dawo-t495s";
    };
}
