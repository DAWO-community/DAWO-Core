# Changelog

## Unreleased

## 0.2.0 - the consumer round

The half the 0.1.3 notes deferred: everything that changes what a consumer
has to do. The security scan's second half (auditd with rules, the last
unguarded dbus own, Secure Boot and TPM2 held together, the disk passphrase
off the command line, deploy host keys verified), the hardening register
finished for SSH and the kernel, and the break a fleet sees when it moves:
vendor hosts gone in favour of generic starter hosts, flat option paths,
the hardware key as a second factor, and the unstable input dropped.

Shipped first as v0.2.0-rc.1 for the hardware test; the tag moves to the
final commit when the test passes. Issues #56 to #171.

Breaking in 0.2.0:

- refactor(hardware): the vendor hardware modules and their hosts
  (dawo-t495s, dawo-t495s-gnome, dawo-hp-probook-4g1i,
  dawo-hp-probook-4g1i-gnome) are removed. The core ships generic starter
  hosts instead (dawo-generic-intel, dawo-generic-amd, and their -gnome
  variants), because hardware choices happen downstream. A fleet that ran a
  vendor host moves the hardware module into its own overlay, or points the
  device at the generic host of the right CPU type. CI builds SBOMs for the
  generic hosts only (#171)
- refactor(options)!: the `options` level is gone from every block, so
  `dawo.ssh.maxAuthTries` rather than `dawo.ssh.options.maxAuthTries`. Six of
  the eight blocks with settings never used that level, so the documented
  convention was the minority practice. Two blocks whose path did not match
  their subject moved as well: `dawo.gnomeHardening` is now
  `dawo.desktop.gnome.hardening`, and `dawo.tools.diagnostics` is now
  `dawo.diagnostics`. Every old name keeps working for one release and warns
  with the new path.
- fix(hardening)!: `dawo.pam.u2f` asks for the key and the password. It used
  the nixpkgs default, `sufficient`, so the key replaced the password instead
  of adding to it. `dawo.pam.u2f.mode = "passwordless"` keeps the old
  behaviour. The recovery path for a lost key is written down in
  docs/users.md (#108). **Breaking** for a device that already has u2f on:
  its users now need both.
- chore(flake)!: the `nixpkgs-unstable` input and the `pkgs.unstable` overlay
  are gone; no module used them (#121). **Breaking for consumers** that
  follow it. Their evaluation stops with `input 'nixpkgs-unstable' follows a
  non-existent input 'dawo/nixpkgs-unstable'`; remove that follows line from
  flake.nix, or declare your own input if you use `pkgs.unstable`.
- feat(localization): `dawo.localization` replaces the two hard-wired locale
  modules. The system language and the regional formats are now separate
  options, the ten most spoken languages in Europe plus Dutch are generated on
  the device so a user can switch the desktop language without a rebuild, and
  each offered language gets its spell checker (#56). Consumers importing
  `localization-nl_nl` or `localization-en_nl` switch to `localization-languages`;
  the defaults reproduce the old Dutch behaviour. The legacy `nl_NL/ISO-8859-1`
  locale is no longer generated.

Security:

- fix(hardening): auditd runs with real rules again. audit 4.2.1 loads what
  4.1.2-unstable rejected, so `dawo.audit.enable` stops being a warning and
  records account changes, commands run as root by a user, and kernel module
  loads, with retention set to five files of 8 MiB. Selected at the hardened
  level as `audit-privileged-actions`; forwarding is not decided yet (#109).
- fix(desktop): KDE Connect is off behind
  `dawo.desktop.plasma.kdeconnect.enable`: it listens on TCP and UDP 1714-1764
  on all interfaces, and the bluetooth dbus policy loses `own="org.bluez"`,
  which let any local user impersonate the Bluetooth daemon (#105).
- fix(boot): a device without Secure Boot refuses TPM2 auto-unlock. PCR 7
  only measures anything with Secure Boot on, so the TPM would otherwise
  hand the disk key to whatever booted; the PCR 7 decision is written down in
  docs/secureboot-tpm.md (#111).
- fix(disko): the LUKS passphrase stays out of the store and the command
  line. disko reads it from `dawo.diskEncryption.passwordFile` on the target,
  imaging copies a 0600 tmpfile there with nixos-anywhere
  `--disk-encryption-keys`, an assertion refuses a store path, and `dawo-proof`
  reports whether the rotation away from the install passphrase has happened
  (#112).
- fix(deploy): a deploy verifies the host key against
  `modules/hosts/known_hosts` before activating a root closure, and magic
  rollback is back on: the new generation must report in over SSH before the
  old one is dropped (#103).
- feat(hardening): two polkit cases are decided instead of inherited from
  whatever the desktop ships: firmware updates ask for an administrator, and
  removable media stays with the person at the keyboard (#115).
- feat(flatpak): `dawo.flatpak.enable` keeps the block on, and
  `dawo.flatpak.autoUpdate` defaults to off (#116) - a second, unpinned
  software supply chain that updated itself weekly and on every activation
  is now a decision rather than a default.

Hardening register:

- refactor(hardening): the SSH floor lives in the register. Turning off
  `ssh-no-root-login`, `ssh-key-only-auth` or `ssh-crypto-floor` now takes the
  setting away as well; before, the switch changed the report and the block
  kept forcing the value. The generated sshd_config is unchanged on every
  host (#110).
- refactor(hardening): the kernel and network sysctls live in the register,
  as eight rules grouped by purpose; four of them are new, for the sixteen
  values that had no rule and could not be turned off by name. Each rule reads
  its values back from the running kernel. The generated sysctl.d file is
  unchanged on every host (#110).

CI and upkeep:

- fix(firefox): the Plasma Integration extension is pinned to a fixed-hash
  XPI from AMO rather than fetched live at build time (#166).
- feat(ci): self-hosted renovate walks the pinned flake inputs and opens a PR
  per input that moved, plus weekly flake.lock maintenance. Nothing
  automerges; validate-nix runs on the PR and a person decides. Renovate is
  pinned by our own flake.lock and runs on our runner, so no hosted bot and
  no third-party token. Needs the RENOVATE_TOKEN secret, set once by an
  admin (#170).

## 0.1.3 - security scan, first round

The first half of the security scan of 3 September, plus what it took to make
main evaluate again. Issues #95 to #158. Everything that changes what a
consumer has to do waits for 0.2.0.

Security:

- fix(users): the deploy credential is out of the repository, sudo for the
  deploy account is scoped to deploy-rs's activation command, and the reason
  it stays a trusted user is written down (#102, #124)
- fix(users): `dawo.bootstrapUser.initialHashedPassword` takes a hash the
  deployment owns; the documented default still works and warns at every
  build (#104, #126)
- feat(hardening): account lockout (five attempts, ten minutes) and password
  quality (twelve characters, two classes) on every host. FIDO2 is wired but
  off (#108, #141)
- feat(hardening): the screen locks after five minutes on both desktops (#106,
  #145), and USB device control is opt-in at the hardened level rather than
  claimed as mandatory (#149)
- feat(hardening): `dawo.hardening` selects security controls per rule instead
  of per block: an ordered level (baseline, hardened, strict), a compliance
  selection that cuts across it, and a switch per rule that wins over both. The
  register also produces `dawo-verify`, which says on the device whether each
  enabled rule holds and why each disabled one is off (#110, #137). The first seven
  rules carry checks only; configuration moves over one subject at a time.
- fix(systemd): the two units this repository defines run with a read-only
  system and only the capabilities they use (#113, #139)
- docs: the mandatory tier lists the three blocks it delivers, not five (#109,
  #150)

Fixes:

- fix(maid): kconfig-declarative is pinned in our own lock; main did not
  evaluate while its upstream URL returned 404 (#97, #98)
- fix(flake): the flake declares its systems, so `nix develop` works (#134,
  #156)
- feat(auto-update): comin takes a credential, so a private overlay updates
  (#95, #99)
- fix(hardware): DisplayLink starts its manager and loads evdi under Wayland,
  not only under X11 (#96, #100)
- feat(update): `dawo-update-status` on every device - service state, last
  poll, last generation and whether a reboot is pending, without sudo. Reads
  comin's own socket where it answers and systemd plus the system profile
  where it does not, so it still reports on a device whose update loop is
  what broke. Desktop notifications are available opt-in through
  `dawo.autoUpdate.desktopNotifications.enable` (#133, #135).
- fix(plasma): the wallet unlocks at the graphical login (#107, #143)
- refactor(maid): the Plasma panel is generated, and GNOME hosts no longer carry
  it (#154)
- fix(version): the release a device reports is read from the newest heading
  in this file. It was a literal, and 0.1.3 shipped saying 0.1.2
- fix(meta): `flake.meta.uri` points at this repository, not a personal fork
  (#152)

CI and upkeep:

- feat(ci): `nix flake check` and an eval of every host on every push (#101,
  #128), and an SBOM per host with a vulnerability report on main (#151, #158).
  The report step itself ran with a flag vulnxscan does not have and failed on
  every run until the fix in this release
- chore(ci): the tree is formatted and linted with treefmt, statix and deadnix
  (#140)
- chore(deps): all inputs updated, nix-maid followed to Codeberg, and two more
  inputs follow our nixpkgs (#63, #129, #138)
- docs: a handbook (#130), three ADRs (#132), and the traps that cost hours
  this round (#155)
- chore(git): union merges for CHANGELOG.md and architecture.md (#157)

## 0.1.2 - the move, and the vulnerability backlog

First release from Codeberg. Issues #55 to #80.

- chore(migration): the fleet and the docs point at Codeberg (#80). Devices
  imaged before the move, with no explicit repoUrl, must be repointed by hand
  once - the fix cannot reach them from the address it replaces.
- feat(printing): `drivers` names a set (`open` / `broad`) instead of taking a
  package list, discovery is separable, and the printer GUI is installed only
  where the desktop lacks one (#76)
- chore(deps): all fifteen flake inputs updated; openssl 3.6.3, expat 2.8.2,
  python 3.13.14, and 7.1.7 on the hosts that follow the latest kernel
  (#62, #71, #72, #74)
- feat(firefox): hunspell spell check dictionaries, and `dawo.firefox.dictionaries`
  to choose which of the eleven a device carries - 26 MB for all of them, 3.0 MB
  for two (#55)

Three vulnerability findings were closed as not applicable rather than fixed,
each with the evidence on the issue: ejs (#67) and simple-git (#69) are not in
the closure at all, and the ffmpeg finding (#73) matched an NVD range of the
form *before 8.1* against `ffmpeg_7` 7.1.5, which already carries the fix
backported to 7.1.4. That shape of finding over-reports against maintained
stable branches and needs a check against the distribution trackers before it
becomes an issue.

## 0.1.1 - audit fixes

Fixes from the first real use of 0.1.0. Issues #35 to #44.

- feat(audio): PipeWire in the core baseline - GNOME hosts had no sound (#35)
- feat(fonts): Noto Color Emoji - tofu boxes in chat and on the web (#36)
- feat(scanning): SANE in the core baseline (#37)
- feat(printing): opt-in CUPS + mDNS printing block (#38)
- fix(update): system.autoUpgrade off; comin is the single update source (#39)
- feat(hardware): NTFS support and zram swap in the base (#40)
- fix(ssh): key-only auth fleet-wide, password login disabled (#41)
- chore(deps): drop 10 dead flake inputs, 25 -> 15 (#42)
- test(checks): coverage gate on the workplace baseline (#43)
- feat(plasma): Tokodon behind dawo.desktop.plasma.socialClient (#44)

Also: a zero-external-dependencies sovereignty plan, an imaging runbook in
docs/, and two flake.lock bumps.

## 0.1.0 - pilot baseline

First tagged DAWO release: the baseline image for the first pilot.

- Lean core with opt-in apps, shell and browser; pilot hosts enable office,
  comms, creative and media so they are productive out of the box.
- Reproducible network install proven on real hardware (ThinkPad T495s and HP
  EliteBook 850 G7).
- Per-model hardware support: a generic baseline plus per-model modules, or
  nixos-facter for unknown models (see modules/hardware/hardware.md).
- Disk encryption (LUKS via disko); GNOME or KDE Plasma, one per host.
- On-device proof: dawo-proof reports the release (0.1.0) next to the exact
  flake revision, so support can read off both per device.

Earlier 0.1.x numbers were never tagged, so the first real release starts at
0.1.0.
