# Hardening

Security controls, and the register that says which of them apply to a device.

## Key Files
- `register.nix` - reads the rule register and turns it into a switch per rule,
  the configuration of the rules that are on, and `dawo-verify`.
- `rules/` - one file per subject, each declaring rules in `flake.dawo.rules`.
  import-tree picks them up; nothing lists them twice.
- `ssh.nix`, `sysctl-baseline.nix`, `timesync.nix` - the mandatory blocks, still
  the place the configuration lives while rules are being moved over.
- `usb-control.nix`, `apparmor.nix`, `gnome-hardening.nix`, `audit.nix` - opt-in
  blocks.

## How a device selects rules

    dawo.hardening.level = "baseline";        # baseline, hardened, strict, or none
    dawo.hardening.compliance = [ "bio" ];    # rules a norm asks for, whatever the level
    dawo.hardening.excludeTags = [ "breaks-vdi" ];
    dawo.hardening.rules."ssh-crypto-floor" = false;   # one rule, either way

`level` is ordered and `compliance` cuts across it, because a norm asks for a set
of rules rather than for a degree of strictness. A per-rule switch wins over
both. See ADR-0010 in `architecture.md`.

## How to add a rule

```nix
{
  flake.dawo.rules."ssh-no-root-login" = {
    title = "SSH refuses a root login";
    severity = "baseline";              # the level it joins at
    tags = [ "remote-access" ];         # for excludeTags
    compliance = [ "bio" "ncsc" ];      # norms that ask for it
    why = ''
      One or two sentences a reviewer can read without opening the code.
    '';
    config = { lib, pkgs }: {
      services.openssh.settings.PermitRootLogin = lib.mkForce "no";
    };
    verify = ''sshd -T 2>/dev/null | grep -qx "permitrootlogin no"'';
  };
}
```

Rules for the same subject go in one file under `rules/`, named after the level
and the subject, for example `baseline-ssh.nix`.

Three things a rule has to honour:

- **`verify` reads and nothing else.** No writing, no restarting, no network. It
  runs daily on every device and after every activation.
- **`verify` proves the state, not the setting.** `sshd -T` says what sshd will
  do; the value in the config file says what somebody wrote down. When they
  disagree, the first one is the answer.
- **`why` is for the person who wants the rule off.** Write the reason it exists,
  not what it does; the code already says what it does.

## Checking a device

    dawo-verify

One line per rule: PASS, FAIL, SKIP with the reason it is off, or NONE when a
rule carries no check yet. It also runs after every activation and on the
`dawo.hardening.verifyOnCalendar` timer, so a fleet tool can read the result out
of the journal.

"No level or norm selected it" is its own answer on purpose. That is the state a
rule is in when nobody chose it, and it is the state a whole tier sat in
unnoticed before this existed.
