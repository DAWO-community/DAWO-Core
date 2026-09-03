{ config, ... }:
let
  # Captured here because the inner module argument of the same name is the
  # NixOS config, not the flake one.
  register = config.flake.dawo.rules;
in
{
  # Turns the rule register (flake.dawo.rules) into three things a device can
  # use: a switch per rule, the configuration of every rule that is on, and a
  # check that says on the device whether each one actually holds.
  #
  # Two axes, deliberately not one. `level` is ordered - baseline, then
  # hardened, then strict - and a rule joins when its own severity fits inside
  # the chosen level. `compliance` cuts across that: a norm asks for a specific
  # set of rules, some of which sit in baseline and some of which sit nowhere,
  # and squeezing that into the ordered scale would force a wrong answer to
  # "is compliance stricter than hardened".
  #
  # Anything can still be set by hand. dawo.hardening.rules.<id> = false takes a
  # rule out of the level that selected it, and = true puts one in that no level
  # did. That is the point of a register: nineteen of twenty rules should not
  # require a fork.
  flake.modules.nixos.hardening-register =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.hardening;

      levels = [
        "baseline"
        "hardened"
        "strict"
      ];
      rank = level: lib.lists.findFirstIndex (l: l == level) 0 levels;

      # Why a rule is off matters as much as that it is off. "Nobody selected
      # it" is the state that let a whole tier go unimported without anything
      # noticing, so it gets a name of its own rather than sharing one with a
      # deliberate exclusion.
      verdict =
        id: rule:
        let
          bySwitch = cfg.rules.${id} or null;
          excludedTags = lib.intersectLists (rule.tags or [ ]) cfg.excludeTags;
          byCompliance = lib.intersectLists (rule.compliance or [ ]) cfg.compliance != [ ];
          byLevel = cfg.level != "none" && rank (rule.severity or "strict") <= rank cfg.level;
        in
        if bySwitch == true then
          {
            on = true;
            why = "set by hand";
          }
        else if bySwitch == false then
          {
            on = false;
            why = "turned off by hand";
          }
        else if excludedTags != [ ] then
          {
            on = false;
            why = "excluded by tag ${lib.concatStringsSep ", " excludedTags}";
          }
        else if byCompliance then
          {
            on = true;
            why = "required by ${lib.concatStringsSep ", " cfg.compliance}";
          }
        else if byLevel then
          {
            on = true;
            why = "in level ${cfg.level}";
          }
        else
          {
            on = false;
            why = "no level or norm selected it";
          };

      verdicts = lib.mapAttrs verdict register;
      enabled = lib.filterAttrs (id: _: verdicts.${id}.on) register;

      checkLine =
        id: rule:
        let
          v = verdicts.${id};
        in
        if !v.on then
          ''printf '  %-38s %-6s %s\n' "${id}" "SKIP" "${v.why}"''
        else if (rule.verify or "") == "" then
          ''printf '  %-38s %-6s %s\n' "${id}" "NONE" "rule carries no check"''
        else
          ''
            if ${rule.verify}
            then printf '  %-38s %-6s %s\n' "${id}" "PASS" "${v.why}"
            else printf '  %-38s %-6s %s\n' "${id}" "FAIL" "${rule.title or id}"; rc=1
            fi
          '';

      dawo-verify = pkgs.writeShellApplication {
        name = "dawo-verify";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          gnused
        ];
        text = ''
          rc=0
          echo "DAWO hardening on $(uname -n), level ${cfg.level}"
          echo
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList checkLine register)}
          echo
          if [ "$rc" -eq 0 ]; then echo "  every enabled rule holds"; else echo "  one or more rules do not hold"; fi
          exit "$rc"
        '';
      };
    in
    {
      options.dawo.hardening = {
        level = lib.mkOption {
          type = lib.types.enum ([ "none" ] ++ levels);
          default = "baseline";
          description = ''
            How much of the register applies. Ordered: `baseline` is what every
            device carries, `hardened` adds what a deployment opts into, and
            `strict` adds what only a raised-risk device wants.

            `none` selects nothing by level, which leaves the per-rule switches
            and the compliance selection as the only way in.
          '';
        };

        compliance = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "bio" ];
          description = ''
            Norms this deployment claims. A rule tagged for one of them is on,
            whatever the level says, because a norm asks for a set of rules
            rather than for a degree of strictness.
          '';
        };

        excludeTags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "breaks-vdi" ];
          description = ''
            Skip every rule carrying one of these tags. For the case where a
            class of rules is known to break something this deployment needs,
            and listing them one by one would go stale.
          '';
        };

        rules = lib.mkOption {
          type = lib.types.attrsOf lib.types.bool;
          default = { };
          example = {
            "ssh-max-auth-tries" = false;
          };
          description = ''
            Per-rule override, and the reason this is a register rather than a
            set of blocks. A rule set here wins over the level and over the
            compliance selection, in both directions.
          '';
        };

        verifyOnCalendar = lib.mkOption {
          type = lib.types.str;
          default = "daily";
          description = ''
            How often the device checks itself, as a systemd calendar
            expression. The result goes to the journal so a fleet tool can read
            it; empty turns the timer off and leaves the check on request and
            after activation.
          '';
        };
      };

      config = lib.mkMerge (
        [
          {
            environment.systemPackages = [ dawo-verify ];

            # After every activation, say whether this generation delivers what
            # it promised. That is the question a git-driven update leaves open:
            # comin says it switched, and this says what it switched to.
            systemd.services.dawo-verify = {
              description = "Check that the hardening rules hold";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${dawo-verify}/bin/dawo-verify";
                # It reads and reports; it has no business writing anything.
                ProtectSystem = "strict";
                ProtectHome = true;
                PrivateTmp = true;
                NoNewPrivileges = true;
                CapabilityBoundingSet = "";
              };
            };

            systemd.timers.dawo-verify = lib.mkIf (cfg.verifyOnCalendar != "") {
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = cfg.verifyOnCalendar;
                Persistent = true;
                RandomizedDelaySec = "30m";
              };
            };

            system.activationScripts.dawoVerify = {
              text = ''
                ${pkgs.systemd}/bin/systemctl start --no-block dawo-verify.service || true
              '';
            };
          }
        ]
        ++ lib.mapAttrsToList (
          _id: rule: rule.config { inherit config lib pkgs; }
        ) enabled
      );
    };
}
