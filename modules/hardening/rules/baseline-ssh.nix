{
  # The SSH floor, as rules. Each one carries its own configuration and its own
  # check, so turning a rule off takes the setting away as well, and the device
  # can say whether the floor holds rather than whether an option was set.
  #
  # Moved here from hardening/ssh.nix. The move was done when the generated
  # sshd_config stayed byte for byte the same on every host.
  #
  # The values are forced, as they were in the block: a host that wants a
  # different floor turns the rule off and says what it wants instead, rather
  # than overriding a rule that still reports PASS.
  #
  # Every check reads. None of them writes, restarts, or asks anything of the
  # network.
  flake.dawo.rules = {
    "ssh-no-root-login" = {
      title = "SSH refuses a root login";
      severity = "baseline";
      tags = [ "remote-access" ];
      compliance = [
        "bio"
        "ncsc"
      ];
      why = ''
        A shared root account over the network leaves no trace of who was there,
        and it is the first thing an untargeted scan tries.
      '';
      config =
        { lib, ... }:
        {
          services.openssh.settings.PermitRootLogin = lib.mkForce "no";
        };
      verify = ''sshd -T 2>/dev/null | grep -qx "permitrootlogin no"'';
    };

    "ssh-key-only-auth" = {
      title = "SSH accepts keys, not passwords";
      severity = "baseline";
      tags = [ "remote-access" ];
      compliance = [
        "bio"
        "ncsc"
      ];
      why = ''
        Password login on a roaming laptop is a brute force surface that costs
        nothing to remove, because the fleet authenticates with keys anyway.
        Console login is unaffected and still takes a password.
      '';
      config =
        { lib, ... }:
        {
          services.openssh.settings = {
            PasswordAuthentication = lib.mkForce false;
            KbdInteractiveAuthentication = lib.mkForce false;
          };
        };
      verify = ''
        sshd -T 2>/dev/null | grep -qx "passwordauthentication no" \
          && sshd -T 2>/dev/null | grep -qx "kbdinteractiveauthentication no"
      '';
    };

    "ssh-crypto-floor" = {
      title = "SSH negotiates only current ciphers, key exchange and MACs";
      severity = "baseline";
      tags = [
        "remote-access"
        "crypto"
      ];
      compliance = [ "ncsc" ];
      why = ''
        The default set carries algorithms kept for compatibility with things
        this fleet does not talk to. Naming the floor means an upgrade cannot
        quietly widen it again.
      '';
      config =
        { lib, ... }:
        {
          services.openssh.settings = {
            Ciphers = lib.mkForce [
              "chacha20-poly1305@openssh.com"
              "aes256-gcm@openssh.com"
              "aes128-gcm@openssh.com"
            ];
            KexAlgorithms = lib.mkForce [
              "curve25519-sha256"
              "curve25519-sha256@libssh.org"
              "diffie-hellman-group16-sha512"
            ];
            Macs = lib.mkForce [
              "hmac-sha2-512-etm@openssh.com"
              "hmac-sha2-256-etm@openssh.com"
            ];
          };
        };
      verify = ''
        sshd -T 2>/dev/null | grep -q "^ciphers .*chacha20-poly1305@openssh.com" \
          && sshd -T 2>/dev/null | grep -q "^kexalgorithms .*curve25519-sha256" \
          && sshd -T 2>/dev/null | grep -q "^macs .*hmac-sha2-512-etm@openssh.com"
      '';
    };
  };
}
