# Headless provisioning ISO. Bakes in wifi + an authorized SSH key so the stick
# boots, auto-joins wifi and brings up sshd unattended; nixos-anywhere then
# drives the install from a workstation (root@<ip>) with no manual
# wpa_supplicant/passwd in the live env. Sidesteps nixos-anywhere's kexec path,
# which is blocked on a hardened DAWO box (kernel.kexec_load_disabled=1).
#
# Org/person-neutral: wifi credentials AND the authorized key come from build-time
# env (kept out of git), so the module stays generic. Build with --impure:
#   WIFI_SSID="MyNet" WIFI_PSK="secret" \
#   INSTALLER_SSH_KEY="ssh-ed25519 AAAA... you@host" \
#     nix build .#nixosConfigurations.dawo-installer.config.system.build.isoImage --impure
#   # result: ./result/iso/*.iso  -> dd to a USB stick
{ ... }:
let
  ssid = builtins.getEnv "WIFI_SSID";
  psk = builtins.getEnv "WIFI_PSK";
  sshKey = builtins.getEnv "INSTALLER_SSH_KEY";
in
{
  flake.modules.nixos."hosts/dawo-installer" =
    { modulesPath, lib, ... }:
    {
      imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

      nixpkgs.hostPlatform = "x86_64-linux";

      # Provisioning specifics arrive via env. They are applied only when set, so
      # the config stays valid under pure eval (nix flake check) without --impure;
      # a build that forgets the env vars produces a useless-but-valid ISO and is
      # flagged by the warning below rather than failing to evaluate.
      warnings = lib.optional (ssid == "" || psk == "" || sshKey == "") ''
        dawo-installer: WIFI_SSID, WIFI_PSK and INSTALLER_SSH_KEY are not all set.
        Build with --impure and those env vars, or the ISO will have no wifi and
        no way to log in.
      '';

      # Declarative wifi -> wpa_supplicant connects headless at boot. The minimal
      # installer ships NetworkManager and force-disables wireless.enable; we want
      # the reverse, so mkForce both. NM and wireless.networks are mutually
      # exclusive (assertion in nixpkgs), hence NM off.
      networking.networkmanager.enable = lib.mkForce false;
      networking.wireless = {
        enable = lib.mkForce true;
        networks = lib.optionalAttrs (ssid != "" && psk != "") {
          ${ssid}.psk = psk;
        };
      };

      # SSH open immediately with the provisioning key -> nixos-anywhere logs in
      # passwordless.
      services.openssh = {
        enable = true;
        settings.PermitRootLogin = lib.mkForce "prohibit-password";
      };
      users.users.root.openssh.authorizedKeys.keys = lib.optionals (sshKey != "") [ sshKey ];

      networking.hostName = lib.mkForce "dawo-installer";
    };
}
