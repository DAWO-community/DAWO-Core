# modules/flake-parts/offline-iso.nix
#
# The offline install stick, v3. Drops nix-offline-iso and builds on
# BerriJ/nixos-installer's offline installer instead (new flake input, see
# below). This REPLACES the previous nix-offline-iso-based module in full,
# keeps the file path, and still replaces the legacy
# modules/hosts/installer/dawo-installer-iso.nix host module (delete it if
# it is still around).
#
# The architectural change that matters: NOTHING is re-evaluated on the
# client. The stick carries the host's pre-built
# config.system.build.toplevel and .diskoScript in the live store
# (their module stages them via system.extraDependencies) and installs
# them VERBATIM: their install-host runs the baked diskoScript, then
# nixos-install --system with the baked toplevel. Every failure the
# previous design hit - the ftpmirror.gnu.org bash fetch, the provenance
# drift behind it, the whole getFlake dead end - lived in the other
# architecture: re-evaluating a pinned config copy on the offline client
# and hoping it reproduces the baked store paths. Verbatim install makes
# that class of bug structurally impossible; the offline-equality rules
# and the environment-dawo-version rewrite are no longer prerequisites
# of the stick (see the post-install note below for where the latter
# still matters).
#
# New flake input (flake.nix), pinned by flake.lock like any other:
#
#   nixos-installer.url = "git+https://codeberg.org/BerriJ/nixos-installer.git";
#
# and remove the now-unused nix-offline-iso input.
#
# What their offline module brings (all of it upstream's, none of it
# ours): the stock installation-cd-minimal base, the staged closures
# (system.extraDependencies), root console + ssh, a known live password,
# and - critical offline - substituters forced to empty on the live
# daemon: a missing store path fails loudly instead of hanging on a
# download attempt. Their interactive install-host (gum menus, keyboard
# switcher, optional blkdiscard, per-step wipe confirmations) stays on
# the stick as a manual fallback.
#
# What OUR front end is: dawo-install, the one-command installer. It
# asks exactly ONE question - the fleet LUKS passphrase, written mode
# 600 to the path the host's layout reads its install-time key from
# (dawo.disk.luks.passwordFile; their script knows nothing about LUKS
# keys) - then runs the whole install unattended from the baked
# store paths: checks every declared disk is present, a 5-second
# Ctrl-C window, the verbatim diskoScript, nixos-install --system with
# the baked toplevel. The same steps their install-host drives
# interactively, with one prompt instead of its menus and
# confirmations.
#
# Run book (per stick, e.g. host dawo-hp-probook-4g1i):
#
#   Build (online machine):
#     nix build .#installer-iso-dawo-hp-probook-4g1i
#     dd the result to a USB stick
#
#   Boot the stick, log in at the console (user "nixos", password
#   "nixos"; or ssh in). wifi if needed (a wifi key stays in the live
#   session only):
#     nmcli device wifi connect "<ssid>" password "<pw>"
#
#   Install, one command:
#     sudo dawo-install
#   It asks exactly one question: the LUKS passphrase (install-time
#   unlock key, NO trailing newline, written mode 600 to the layout's
#   key path; a pre-created non-empty file is used as-is, so
#   scripted installs skip the prompt). Everything after runs
#   unattended: declared-disk check, 5-second Ctrl-C window, the baked
#   diskoScript (partition/format/mount), then nixos-install --system
#   with the baked closure (--no-channel-copy --no-root-passwd, the
#   same flags their install-host uses). No network at any step; a
#   missing store path aborts with a clear error.
#
#   Their interactive install-host stays on the stick as a manual
#   fallback (host/disk menus, keyboard switcher, optional blkdiscard,
#   per-step confirmations) for the odd box that needs hand-holding.
#
#   Post-install: unlike the previous design, the stick does NOT seed
#   /etc/nixos with a pinned config copy; the machine joins the fleet
#   through the normal deploy-rs/comin flow (docs/deploy.md). Offline
#   post-install REBUILDS are therefore not provided by this stick;
#   if that ever becomes a requirement, it needs the whole pinned-cfg
#   seeding plus the provenance-free environment-dawo-version rewrite
#   (parked in the dawo-version canvas), whatever the installer.
#   Secure Boot stays off at install time as before (sbctl ceremony
#   after).
#
# Trade-offs, stated plainly:
#   - The live ISO base is evaluated against OUR nixpkgs (26.05), not
#     the installer's own pin (unstable) - we consume it as a NixOS
#     module, not through its lib helpers, exactly so the stick stays in
#     our store world like the baked closures. Their module's options
#     are all long-stable ones; still, re-check on every input bump.
#   - import "${installer}/iso" is internal API, not a flake output:
#     the same bet on their layout the previous design made on
#     nix-offline-iso's nix/lib.nix. The flake.lock pin keeps it
#     survivable; re-check on every bump.
#   - One ISO still carries one host (see the view below). Their module
#     supports a fleet-wide stick natively: hand it an unfiltered self
#     and install-host's host menu does the picking.
#   - The live `disko` CLI, should anyone run it manually, is the
#     INSTALLER's disko pin; the actual install always runs the
#     diskoScript baked from OUR disko pin with the host closure.
#   - The live keyboard layout is forced to "us" below: their module
#     defaults to "de", and a plain assignment beats their mkDefault.
#     install-host's manual flow still offers its own layout switcher
#     (its question text hardcodes "de"), visible only when run by
#     hand. The passphrase is the one thing typed into this stick, so
#     layout accuracy here is LUKS accuracy.
#   - The wipe confirmations are gone with the questions: after the
#     LUKS prompt, dawo-install's only brake is the 5-second Ctrl-C
#     window. For machines that deserve hand-holding, run their
#     install-host manually; it still asks at every step.
{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  # The stick is x86_64 only, like the fleet (their module hardcodes
  # x86_64 too).
  system = "x86_64-linux";

  # Every name here gets its own stick (package installer-iso-<host>).
  # A host must declare a non-empty disko layout: the baked diskoScript
  # is the entire partition/format step, and install-host refuses at
  # the client if a declared disk device is not present on the machine.
  offlineTargets = [
    "dawo-generic-x86"
  ];

  installer = inputs.nixos-installer;

  # Their offline live-ISO module, evaluated against our nixpkgs via
  # the nixosSystem call below. import "<installer>/iso" is their
  # module's own entry shape ({ disko, offline }), the same one their
  # flake wraps as nixosModules.isoOffline; we wrap it ourselves only
  # so the live disko CLI comes from OUR disko pin instead of theirs.
  installerModule = import "${installer}/iso" {
    inherit (inputs) disko;
    offline = true;
  };

  pkgs = inputs.nixpkgs.legacyPackages.${system};

  # Eval-time guards, as before: fail the ISO build, not the client.
  checkTarget =
    name:
    if !(config.flake.nixosConfigurations ? ${name}) then
      throw "offline-iso: host ${name} (offlineTargets) is not in flake.nixosConfigurations"
    else if !(config.flake.nixosConfigurations.${name}.options ? disko.devices) then
      throw "offline-iso: host ${name} does not import disko; the stick cannot partition it"
    else if config.flake.nixosConfigurations.${name}.config.disko.devices == { } then
      throw "offline-iso: host ${name} declares an empty disko.devices"
    else
      name;
  targets = map checkTarget offlineTargets;

  # The one-command installer. ONE prompt (the fleet LUKS key), then
  # unattended: the disk(s) the host's layout declares are verified,
  # then the baked diskoScript and nixos-install with the baked
  # toplevel - the same steps their install-host drives interactively.
  # Toplevel, diskoScript and the disk name->device lines are baked in
  # at ISO build time; this stick installs exactly one host, so the
  # passphrase is the only runtime choice left.
  dawoInstall =
    hostName:
    let
      host = config.flake.nixosConfigurations.${hostName};
      topLevel = host.config.system.build.toplevel;
      diskoScript = host.config.system.build.diskoScript;
      # Where the host's disk layout reads its install-time LUKS key. A
      # layout without the option reads the historic /tmp/secret.key.
      keyFile = lib.attrByPath [ "dawo" "disk" "luks" "passwordFile" ] "/tmp/secret.key" host.config;
      keyArg = lib.escapeShellArg keyFile;
      diskLines = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: d: "${name} ${d.device}") host.config.disko.devices.disk
      );
    in
    pkgs.writeShellApplication {
      name = "dawo-install";
      runtimeInputs = [
        pkgs.util-linux
        # The script calls it directly now (no exec install-host, no
        # assumptions about the live base's PATH).
        pkgs.nixos-install-tools
      ];
      text = ''
                die() {
                  echo "dawo-install: $*" >&2
                  exit 1
                }

                [ "$(id -u)" -eq 0 ] || die "must run as root (try: sudo dawo-install)"

                echo "DAWO offline installer for ${hostName}"
                echo
                lsblk --nodeps --output NAME,SIZE,TYPE,MODEL 2>/dev/null || true
                echo

                # The layout reads its install-time key from ${keyFile}; NO
                # trailing newline (printf '%s'). An existing non-empty file is
                # used as-is, so scripted installs can pre-create it instead of
                # answering prompts.
                if [ -s ${keyArg} ]; then
                  echo "Using the existing "${keyArg}"."
                else
                  umask 077
                  while true; do
                    read -r -s -p "LUKS passphrase (install-time unlock key): " pw1
                    echo >&2
                    read -r -s -p "Repeat passphrase: " pw2
                    echo >&2
                    if [ -z "$pw1" ]; then
                      echo "Empty passphrase; try again." >&2
                    elif [ "$pw1" = "$pw2" ]; then
                      break
                    else
                      echo "Passphrases differ; try again." >&2
                    fi
                  done
                  printf '%s' "$pw1" > ${keyArg}
                  unset pw1 pw2
                fi
                echo

                # Every disk this host's disko layout declares, checked BEFORE
                # anything wipes. A missing device dies here with the layout
                # name, not mid-partition.
                echo "Disk(s) declared by ${hostName}'s layout:"
                missing=0
                while read -r name dev; do
                  [ -n "$name" ] || continue
                  echo "  $name: $dev"
                  if [ ! -b "$dev" ]; then
                    echo "    not a block device on this machine" >&2
                    missing=1
                  fi
                done <<'EOF'
        ${diskLines}
        EOF
                [ "$missing" -eq 0 ] || die "a declared disk is missing; fix the host or the machine"

                # Their install-host asks per-step confirmations here; this is
                # the one-prompt flow, so the 5-second Ctrl-C window is the
                # brake. https://codeberg.org/BerriJ/nixos-installer
                echo
                echo "Wiping the disk(s) above and installing ${hostName} in 5 seconds."
                echo "Ctrl-C NOW to abort."
                for i in 5 4 3 2 1; do
                  echo "  ...$i"
                  sleep 1
                done
                echo

                # Partition/format/mount, verbatim from the baked script:
                ${diskoScript}

                sync
                chmod o+rx /mnt

                # Their install-host's exact invocation, flags verbatim:
                # one command, no channel copy, no root-password question.
                # The closure is in the live store and the daemon has empty
                # substituters, so this either completes or fails loudly.
                nixos-install \
                  --no-channel-copy \
                  --no-root-passwd \
                  --system ${topLevel} \
                  --root /mnt

                echo
                echo "Done. Power off, remove the stick, boot the machine."
      '';
    };

  isoFor =
    hostName:
    let
      host = config.flake.nixosConfigurations.${hostName};

      # One-config view of this flake, same trick as the previous
      # design: their hosts.nix enumerates installable hosts from
      # self.nixosConfigurations, pre-evaluates the installer's
      # host->toplevel/diskoScript and host->device tables at ISO build
      # time, and their install-host turns those tables into the client
      # menus. Handing it a one-host view bakes exactly one installable
      # machine into the stick; an unfiltered self builds a fleet-wide
      # stick instead (their host menu does the picking).
      #
      # The lib fallback: their module reads self.lib.flake-origin or
      # null, and `or` only guards the LAST attribute - a flake without
      # a lib output would explode on the missing self.lib itself.
      # flake-parts does not create lib by default, so the view always
      # carries one: the real one if we expose flake.lib, an empty
      # attrset as the no-origin offline stand-in.
      view = self // {
        lib = self.lib or { };
        nixosConfigurations = {
          ${hostName} = host;
        };
      };
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        self = view;
      };
      modules = [
        installerModule

        # This stick's front end plus the one command their flow depends
        # on but nothing guarantees: install-host's final step is
        # `nixos-install`; do not assume the installation-cd base ships
        # it, put it on PATH explicitly (nixos-install-tools also brings
        # nixos-generate-config and nixos-enter for offline recovery
        # work on the stick). environment.systemPackages is a list
        # merge, so their install-host, disko, gum, fzf etc. stay on
        # PATH alongside dawo-install.
        {
          # Live-session keyboard: their module defaults to "de", a
          # plain assignment beats their mkDefault.
          console.keyMap = "us";

          environment.systemPackages = [
            pkgs.nixos-install-tools
            (dawoInstall hostName)
          ];
        }
      ];
    };
in
{
  # One stick per offline target:
  #   nix build .#installer-iso-dawo-hp-probook-4g1i
  flake.packages.${system} = lib.genAttrs (map (host: "installer-iso-${host}") targets) (
    name: (isoFor (lib.removePrefix "installer-iso-" name)).config.system.build.isoImage
  );
}
