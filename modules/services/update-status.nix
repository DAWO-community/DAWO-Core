{
  # On-device visibility for the auto-update loop: `dawo-update-status`, a
  # one-screen answer to "is this laptop still being updated, and when last?".
  #
  # comin already exposes its state over a gRPC socket (`comin status`), but
  # that output is operator-shaped and English, and it says nothing when comin
  # itself is dead or too old to have the subcommand. This wraps it: comin's
  # state when the socket answers, systemd plus the system profile when it does
  # not, so the script still tells the truth on a device where the update loop
  # is exactly what is broken. Every source it reads is world-readable, so a
  # user without sudo gets the same answer as an operator.
  flake.modules.nixos.services-update-status =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.autoUpdate;

      # What the device is configured to follow. Read from services.comin, not
      # from dawo.autoUpdate.options, because an overlay may override the
      # remotes wholesale (Zaanstad does, to add a deploy key) and the script
      # must report what comin actually got.
      remoteRows = lib.concatMapStringsSep "\n" (
        r: ''row "Volgt" "${r.url} (${r.branches.main.name})"''
      ) config.services.comin.remotes;

      dawo-update-status = pkgs.writeShellApplication {
        name = "dawo-update-status";
        runtimeInputs = with pkgs; [
          coreutils
          jq
          systemd
        ];
        text = ''
          socket=/var/lib/comin/grpc.sock

          usage() {
            cat <<'USAGE'
          dawo-update-status - staat van de automatische updates op dit toestel

            dawo-update-status          samenvatting
            dawo-update-status --log    laatste 50 regels van het update-logboek
            dawo-update-status --json   ruwe comin-status (voor support)
          USAGE
          }

          # "3 minuten geleden" from an epoch second, or a dash when unknown.
          ago() {
            local then=''${1:-} now diff
            if [ -z "$then" ]; then printf -- '-'; return; fi
            now=$(date +%s)
            diff=$((now - then))
            if [ "$diff" -lt 0 ]; then printf 'in de toekomst'
            elif [ "$diff" -lt 90 ]; then printf 'zojuist'
            elif [ "$diff" -lt 5400 ]; then printf '%s minuten geleden' "$((diff / 60))"
            elif [ "$diff" -lt 172800 ]; then printf '%s uur geleden' "$((diff / 3600))"
            else printf '%s dagen geleden' "$((diff / 86400))"
            fi
          }

          # RFC3339 (comin) or a systemd timestamp -> epoch seconds; empty when
          # absent or unparseable, which every caller treats as "unknown".
          epoch_of() {
            local ts=''${1:-}
            if [ -z "$ts" ] || [ "$ts" = "null" ]; then return 0; fi
            date -d "$ts" +%s 2>/dev/null || true
          }

          stamp() {
            local e=''${1:-}
            if [ -z "$e" ]; then printf -- '-'; return; fi
            date -d "@$e" '+%Y-%m-%d %H:%M'
          }

          row() { printf '  %-18s %s\n' "$1" "$2"; }

          case "''${1:-}" in
            -h|--help) usage; exit 0 ;;
            --log)
              if ! journalctl -u comin -n 50 --no-pager 2>/dev/null; then
                echo "Geen toegang tot het logboek. Probeer: sudo dawo-update-status --log" >&2
                exit 1
              fi
              exit 0
              ;;
            --json)
              if [ -S "$socket" ] && command -v comin >/dev/null; then
                comin status --json
                exit 0
              fi
              echo "comin antwoordt niet op $socket" >&2
              exit 1
              ;;
            "") ;;
            *) usage >&2; exit 2 ;;
          esac

          # --- the service itself ----------------------------------------------
          active=$(systemctl show comin --property=ActiveState --value 2>/dev/null || echo unknown)
          since=$(epoch_of "$(systemctl show comin --property=ActiveEnterTimestamp --value 2>/dev/null || true)")

          # --- comin's own view, when the socket answers ------------------------
          state=""
          if [ -S "$socket" ] && command -v comin >/dev/null; then
            state=$(timeout 5 comin status --json 2>/dev/null || true)
          fi

          fetched=""
          fetch_err=""
          deploy_status=""
          deploy_ended=""
          deploy_err=""
          reboot=""
          suspended=""
          if [ -n "$state" ]; then
            fetched=$(epoch_of "$(jq -r '[.fetcher.repository_status.remotes[]?.fetched_at] | map(select(. != null)) | max // empty' <<<"$state")")
            fetch_err=$(jq -r '[.fetcher.repository_status.remotes[]?.fetch_error_msg, .fetcher.repository_status.error_msg] | map(select(. != null and . != "")) | first // empty' <<<"$state")
            deploy_status=$(jq -r '.deployer.deployment.status // empty' <<<"$state")
            deploy_ended=$(epoch_of "$(jq -r '.deployer.deployment.ended_at // empty' <<<"$state")")
            deploy_err=$(jq -r '.deployer.deployment.error_msg // empty' <<<"$state")
            reboot=$(jq -r '.need_to_reboot // empty' <<<"$state")
            suspended=$(jq -r '.is_suspended // empty' <<<"$state")
          fi

          # --- what actually landed ---------------------------------------------
          # NOT /nix/var/nix/profiles/system: comin never advances it. It sets
          # its own profile in /nix/var/nix/profiles/system-profiles/comin
          # (internal/profile/profile.go), a directory that is mode 0000, so a
          # user cannot read it either. On a comin device the system profile
          # still points at the last manual nixos-rebuild - which is also why
          # `nixos-rebuild list-generations` names a stale generation "Current"
          # there. /run/current-system is world-readable and is the truth about
          # what this boot is running.
          current=""
          if [ -e /run/current-system ]; then
            current=$(readlink -f /run/current-system 2>/dev/null || true)
          fi
          # The symlink is rewritten on every activation, so its mtime is the
          # last switch or the boot, whichever came last.
          current_time=$(stat -c %Y /run/current-system 2>/dev/null || true)

          # Fallback reboot check, also taken when comin reported false (jq
          # reads a false through `// empty` as absent): a switched kernel or
          # initrd is live only after a reboot.
          if [ -z "$reboot" ]; then
            reboot=false
            for part in kernel initrd kernel-modules; do
              a=$(readlink -f "/run/booted-system/$part" 2>/dev/null || true)
              b=$(readlink -f "/run/current-system/$part" 2>/dev/null || true)
              if [ "$a" != "$b" ]; then reboot=true; fi
            done
          fi

          echo "DAWO automatische updates op $(uname -n)"
          echo
          if [ "$active" = "active" ]; then
            row "Update-dienst" "actief sinds $(stamp "$since") ($(ago "$since"))"
          else
            row "Update-dienst" "NIET ACTIEF ($active)"
          fi
          ${remoteRows}
          if [ -n "$state" ]; then
            row "Laatste controle" "$(stamp "$fetched") ($(ago "$fetched"))"
          else
            row "Laatste controle" "onbekend (comin geeft geen status; zie --log)"
          fi
          if [ -n "$deploy_ended" ] && [ "$deploy_status" = "done" ]; then
            row "Laatste update" "$(stamp "$deploy_ended") ($(ago "$deploy_ended"))"
          else
            row "Systeem sinds" "$(stamp "$current_time") ($(ago "$current_time"))"
          fi
          if [ -n "$current" ]; then
            row "Draait nu" "$current"
          fi
          if [ "$reboot" = "true" ]; then
            row "Herstart nodig" "ja, om de nieuwe kernel te gebruiken"
          else
            row "Herstart nodig" "nee"
          fi
          if [ "$suspended" = "true" ]; then
            row "Gepauzeerd" "ja, updates staan stil"
          fi

          echo
          if [ "$active" != "active" ]; then
            echo "  PROBLEEM: de update-dienst draait niet. Meld dit bij de beheerder."
          elif [ -n "$fetch_err" ]; then
            echo "  PROBLEEM bij het ophalen: $fetch_err"
          elif [ "$deploy_status" = "failed" ]; then
            echo "  PROBLEEM bij het uitrollen ($(stamp "$deploy_ended")): ''${deploy_err:-geen melding}"
            echo "  Het toestel draait nog op de vorige, werkende versie."
          elif [ -n "$fetched" ] && [ "$(($(date +%s) - fetched))" -gt 172800 ]; then
            echo "  LET OP: meer dan twee dagen niets opgehaald. Netwerk of toegang?"
          else
            echo "  Alles in orde."
          fi
          echo "  Details voor support: dawo-update-status --log"
        '';
      };
    in
    {
      options.dawo.autoUpdate.desktopNotifications.enable = lib.mkEnableOption ''
        desktop notifications on build/deploy events (comin's own user service).
        Off by default: it also notifies at every graphical login, which is
        noise on a device that updates cleanly. Turn it on where an update is
        being watched
      '';

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ dawo-update-status ];
        services.comin.desktop = lib.mkIf cfg.desktopNotifications.enable {
          enable = true;
          title = "DAWO updates";
        };
      };
    };
}
