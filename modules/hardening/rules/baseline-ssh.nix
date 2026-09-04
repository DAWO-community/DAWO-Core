{
  # The SSH floor, as rules. Configuration still comes from hardening/ssh.nix;
  # these carry the checks, so the device can say whether the floor actually
  # holds rather than whether an option was set. The configuration moves here
  # one subject at a time, and each move is done when the built configuration
  # does not change.
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
      config = _: { };
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
      config = _: { };
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
      config = _: { };
      verify = ''
        sshd -T 2>/dev/null | grep -q "^ciphers .*chacha20-poly1305@openssh.com" \
          && sshd -T 2>/dev/null | grep -q "^kexalgorithms .*curve25519-sha256" \
          && sshd -T 2>/dev/null | grep -q "^macs .*hmac-sha2-512-etm@openssh.com"
      '';
    };
  };
}
