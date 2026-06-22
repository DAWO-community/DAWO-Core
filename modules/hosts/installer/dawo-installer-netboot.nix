# Netboot (PXE/iPXE) variant of the provisioning installer. Boots over ethernet
# from a PXE server (e.g. an operator laptop running dnsmasq), so a fleet can be
# imaged without a USB stick per machine. Produces kernel + initrd + an iPXE
# script (system.build.{kernel,netbootRamdisk,netbootIpxeScript}); ethernet/DHCP
# means no wifi credentials are needed. sshd + the provisioning key are baked in,
# so nixos-anywhere drives the install from the operator over the same wired LAN
# (no AP client-isolation, unlike a phone hotspot). Build with --impure:
#   INSTALLER_SSH_KEY="ssh-ed25519 AAAA... you@host" \
#     nix build .#nixosConfigurations.dawo-installer-netboot.config.system.build.netbootRamdisk --impure
{ ... }:
let
  sshKey = builtins.getEnv "INSTALLER_SSH_KEY";
in
{
  flake.modules.nixos."hosts/dawo-installer-netboot" =
    { modulesPath, lib, ... }:
    {
      imports = [ (modulesPath + "/installer/netboot/netboot-minimal.nix") ];

      nixpkgs.hostPlatform = "x86_64-linux";

      warnings = lib.optional (sshKey == "") ''
        dawo-installer-netboot: INSTALLER_SSH_KEY is not set. Build with --impure
        and that env var, or the netboot image will have no way to log in.
      '';

      # sshd open immediately with the provisioning key -> nixos-anywhere logs in
      # passwordless over the wired LAN.
      services.openssh = {
        enable = true;
        settings.PermitRootLogin = lib.mkForce "prohibit-password";
      };
      users.users.root.openssh.authorizedKeys.keys = lib.optionals (sshKey != "") [ sshKey ];

      networking.hostName = lib.mkForce "dawo-installer-netboot";
    };
}
