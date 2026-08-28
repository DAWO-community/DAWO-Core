{ inputs, ... }:
{
  # The Plasma workspace as it is handed to a user: branding, the panel layout,
  # and the settings a fresh account starts with.
  #
  # Named "generic" for historical reasons; it is Plasma-specific throughout,
  # which is why the whole thing sits behind dawo.desktop.plasma.enable. It used
  # to be imported unconditionally, so GNOME devices carried a KDE panel
  # definition and a service that deleted KDE files out of their home
  # directories.
  flake.modules.nixos.maid-dawo-generic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      wallpaper = pkgs.stdenvNoCC.mkDerivation {
        name = "wallpaper";
        src = ../../artwork/wallpapers/DAWO-achtergrond.png;
        dontUnpack = true;
        installPhase = ''
          cp $src $out
        '';
      };

      # Plasma numbers containments per screen: the desktop is screen+1, the panel
      # is (screen+1)*100, an applet is that panel number plus its position, and
      # a nested applet is the applet id with two more digits. So everything
      # below follows from the screen index, and the five hand-written copies
      # this replaces were five chances to edit one and forget the other four.
      #
      # Checked rather than asserted: the rendered
      # plasma-org.kde.plasma.desktop-appletsrc is identical to what those five
      # produced.
      screens = [
        0
        1
        2
        3
        4
      ];

      mkDesktop = screen: {
          Wallpaper = {
            "org.kde.image" = {
              General = {
                Image = "/nix/store/vxchhzr0jkpz1gwcy7wm5kk4gvp6fhc9-wallpaper";
              };
            };
          };
          activityId = "c2b12168-8128-4075-8bce-38fb70b77c7a";
          formfactor = 0;
          immutability = 1;
          location = 0;
          plugin = "org.kde.plasma.folder";
          wallpaperplugin = "org.kde.image";
        } // { lastScreen = screen; };

      mkPanel =
        screen:
        let
          panel = (screen + 1) * 100;
          a = n: toString (panel + n);
        in
        {
          activityId = "";
          formfactor = 2;
          immutability = 1;
          lastScreen = screen;
          location = 4;
          plugin = "org.kde.panel";
          wallpaperplugin = "org.kde.image";
          Applets = {
            "${a 1}" = {
              Configuration = {
                Appearance = {
                  chartFace = "org.kde.ksysguard.barchart";
                  title = "Individual Core Usage";
                };
                CurrentPreset = "org.kde.plasma.systemmonitor";
                Sensors = {
                  highPrioritySensorIds = "[\"cpu/cpu.*/usage\"]";
                  totalSensors = "[\"cpu/all/usage\"]";
                };
                popupHeight = 375;
                popupWidth = 525;
              };
              immutability = 1;
              plugin = "org.kde.plasma.systemmonitor.cpucore";
            };
            "${a 2}" = {
              Configuration = {
                Appearance = {
                  chartFace = "org.kde.ksysguard.piechart";
                  title = "Memory Usage";
                };
                CurrentPreset = "org.kde.plasma.systemmonitor";
                Sensors = {
                  highPrioritySensorIds = "[\"memory/physical/used\"]";
                  lowPrioritySensorIds = "[\"memory/physical/total\"]";
                  totalSensors = "[\"memory/physical/usedPercent\"]";
                };
                popupHeight = 375;
                popupWidth = 525;
              };
              immutability = 1;
              plugin = "org.kde.plasma.systemmonitor.memory";
            };
            "${a 3}" = {
              immutability = 1;
              plugin = "org.kde.plasma.panelspacer";
            };
            "${a 4}" = {
              Configuration = {
                General = {
                  favoritesPortedToKAstats = true;
                  icon = "app-launcher";
                };
                popupHeight = 493;
                popupWidth = 633;
              };
              immutability = 1;
              plugin = "org.kde.plasma.kickoff";
            };
            "${a 5}" = {
              immutability = 1;
              plugin = "org.kde.plasma.pager";
            };
            "${a 6}" = {
              immutability = 1;
              plugin = "org.kde.plasma.marginsseparator";
            };
            "${a 7}" = {
              immutability = 1;
              plugin = "org.kde.plasma.icontasks";
            };
            "${a 8}" = {
              immutability = 1;
              plugin = "org.kde.plasma.panelspacer";
            };
            "${a 9}" = {
              Applets = {
                "${a 9}01" = {
                  immutability = 1;
                  plugin = "org.kde.kdeconnect";
                };
                "${a 9}02" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.cameraindicator";
                };
                "${a 9}03" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.clipboard";
                };
                "${a 9}04" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.devicenotifier";
                };
                "${a 9}05" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.manage-inputmethod";
                };
                "${a 9}06" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.notifications";
                };
                "${a 9}07" = {
                  immutability = 1;
                  plugin = "org.kde.kscreen";
                };
                "${a 9}08" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.keyboardindicator";
                };
                "${a 9}09" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.keyboardlayout";
                };
                "${a 9}10" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.networkmanagement";
                };
                "${a 9}11" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.printmanager";
                };
                "${a 9}12" = {
                  Configuration = {
                    General = {
                      migrated = true;
                    };
                  };
                  immutability = 1;
                  plugin = "org.kde.plasma.volume";
                };
                "${a 9}13" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.weather";
                };
                "${a 9}14" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.brightness";
                };
                "${a 9}15" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.battery";
                };
                "${a 9}16" = {
                  immutability = 1;
                  plugin = "org.kde.plasma.bluetooth";
                };
              };
              General = {
                extraItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather,org.kde.plasma.battery";
                knownItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather";
                shownItems = "org.kde.plasma.battery";
              };
              activityId = "";
              formfactor = 0;
              immutability = 1;
              lastScreen = -1;
              location = 0;
              plugin = "org.kde.plasma.systemtray";
              popupHeight = 432;
              popupWidth = 432;
              wallpaperplugin = "org.kde.image";
            };
            "${a 10}" = {
              Configuration = {
                popupHeight = 375;
                popupWidth = 525;
              };
              immutability = 1;
              plugin = "org.kde.plasma.digitalclock";
            };
            "${a 11}" = {
              immutability = 1;
              plugin = "org.kde.plasma.showdesktop";
            };
          };
          General.AppletOrder = "${a 1};${a 2};${a 3};${a 4};${a 5};${a 6};${a 7};${a 8};${a 9};${a 10};${a 11}";
        };

      containments =
        builtins.listToAttrs (
          map (s: {
            name = toString (s + 1);
            value = mkDesktop s;
          }) screens
        )
        // builtins.listToAttrs (
          map (s: {
            name = toString ((s + 1) * 100);
            value = mkPanel s;
          }) screens
        );

      panelViews = builtins.listToAttrs (
        map (s: {
          name = "Panel ${toString ((s + 1) * 100)}";
          value = {
            floating = 1;
            Defaults.thickness = 44;
          };
        }) screens
      );

    in
    {
      imports = [
        inputs.nix-maid.nixosModules.default
      ];

      config = lib.mkIf config.dawo.desktop.plasma.enable {
      systemd.services."kdeconfig-cleanup" = {
        wantedBy = [ "maid-system-activation.service" ];
        script = ''
          set -eu
          find /home/*/.config -maxdepth 1 -type f -name "kactivitymanagerdrc" -delete
          find /home/*/.config -maxdepth 1 -type f -name "kcminputrc" -delete
          find /home/*/.config -maxdepth 1 -type f -name "kdeglobals" -delete
          find /home/*/.config -maxdepth 1 -type f -name "kscreenlockerrc" -delete
          find /home/*/.config -maxdepth 1 -type f -name "kwinrc" -delete
          find /home/*/.config -maxdepth 1 -type f -name "plasmarc" -delete
          find /home/*/.config -maxdepth 1 -type f -name "plasmashellrc" -delete
          find /home/*/.config -maxdepth 1 -type f -name "plasma-org.kde.plasma.desktop-appletsrc" -delete
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
      maid.sharedModulesForAllUsers = true;
      maid.sharedModules = [
        {
          packages = [ pkgs.git ];

          file.home.".face".source = ../../artwork/icons/logo-rijksoverheid-square.png;
          file.home.".face.icon".source = ../../artwork/icons/logo-rijksoverheid-square.png;

          # Built from our own pinned input rather than nix-maid's default,
          # which resolves through npins outside flake.lock and fetches from
          # the live network at eval time. See the note on the input in
          # flake.nix.
          kconfig.package = pkgs.callPackage inputs.kconfig-declarative { };

          kconfig.settings = {
            kactivitymanagerdrc = {
              activities = {
                c2b12168-8128-4075-8bce-38fb70b77c7a = "Default";
              };
            };
            kcminputrc = {
              Keyboard = {
                NumLock = 0;
              };
              Mouse = {
                cursorTheme = "breeze_cursors";
              };
            };
            kdeglobals = {
              General = {
                XftAntialias = true;
                XftHintStyle = "hintslight";
                XftSubPixel = "rgb";
                fixed = "Fira Code,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
                font = "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
                menuFont = "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
                smallestReadableFont = "Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
                toolBarFont = "Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
              };
              Icons = {
                Theme = "Papirus";
              };
              KDE = {
                LookAndFeelPackage = "org.kde.breeze.desktop";
              };
            };
            kscreenlockerrc = {
              Daemon = {
                LockOnResume = true;
                LockGrace = 0;
                Timeout = 5;
              };
              Greeter = {
                WallpaperPlugin = "org.kde.image";
                Wallpaper = {
                  "org.kde.image" = {
                    General = {
                      Image = wallpaper;
                    };
                  };
                };
              };
            };
            kwinrc = {
              Plugins = {
                blurEnabled = true;
                kwin4_effect_geometry_changeEnabled = true;
                magiclampEnabled = true;
              };
            };
            plasmarc = {
              Theme = {
                name = "default";
              };
              Wallpapers = {
                usersWallpapers = wallpaper;
              };
            };
            plasmashellrc = {
              PlasmaViews = panelViews;
            };
            "plasma-org.kde.plasma.desktop-appletsrc" = {
              ActionPlugins = {
                              "0" = {
                                "MiddleButton;NoModifier" = "org.kde.paste";
                                "RightButton;NoModifier" = "org.kde.contextmenu";
                              };
                              "1" = {
                                "RightButton;NoModifier" = "org.kde.contextmenu";
                              };
                            };
              Containments = containments;
            };
          };
        }
      ];
      };
    };
}
