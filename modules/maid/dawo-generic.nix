{ inputs, ... }:
{
  flake.modules.nixos.maid-dawo-generic =
    { pkgs, ... }:
    let
      # Define the custom background package with the correct relative path
      wallpaper = pkgs.stdenvNoCC.mkDerivation {
        name = "wallpaper";
        src = ../../artwork/wallpapers/DAWO-achtergrond.png;
        dontUnpack = true;
        installPhase = ''
          cp $src $out
        '';
      };
    in
    {
      imports = [
        inputs.nix-maid.nixosModules.default
      ];

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

          # Root walking through directories users can write is the classic
          # place to be handed a symlink, so give it the least that still lets
          # it do the one job. It needs /home writable and the two capabilities
          # that let root delete a file it does not own; everything else is off.
          ProtectSystem = "strict";
          ReadWritePaths = [ "/home" ];
          PrivateTmp = true;
          PrivateNetwork = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [ ];
          NoNewPrivileges = true;
          CapabilityBoundingSet = [
            "CAP_DAC_OVERRIDE"
            "CAP_FOWNER"
          ];
        };
      };
      maid.sharedModulesForAllUsers = true;
      maid.sharedModules = [
        {
          packages = [ pkgs.git ];

          file.home.".face".source = ../../artwork/icons/logo-rijksoverheid-square.png;
          file.home.".face.icon".source = ../../artwork/icons/logo-rijksoverheid-square.png;

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
              PlasmaViews."Panel 100" = {
                floating = 1;
                Defaults = {
                  thickness = 44;
                };
              };
              PlasmaViews."Panel 200" = {
                floating = 1;
                Defaults = {
                  thickness = 44;
                };
              };
              PlasmaViews."Panel 300" = {
                floating = 1;
                Defaults = {
                  thickness = 44;
                };
              };
              PlasmaViews."Panel 400" = {
                floating = 1;
                Defaults = {
                  thickness = 44;
                };
              };
              PlasmaViews."Panel 500" = {
                floating = 1;
                Defaults = {
                  thickness = 44;
                };
              };
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
              Containments = {
                # Desktops
                "1" = {
                  activityId = "c2b12168-8128-4075-8bce-38fb70b77c7a";
                  formfactor = 0;
                  immutability = 1;
                  lastScreen = 0;
                  location = 0;
                  plugin = "org.kde.plasma.folder";
                  wallpaperplugin = "org.kde.image";
                  Wallpaper."org.kde.image".General = {
                    Image = wallpaper;
                  };
                };
                "2" = {
                  activityId = "c2b12168-8128-4075-8bce-38fb70b77c7a";
                  formfactor = 0;
                  immutability = 1;
                  lastScreen = 1;
                  location = 0;
                  plugin = "org.kde.plasma.folder";
                  wallpaperplugin = "org.kde.image";
                  Wallpaper."org.kde.image".General = {
                    Image = wallpaper;
                  };
                };
                "3" = {
                  activityId = "c2b12168-8128-4075-8bce-38fb70b77c7a";
                  formfactor = 0;
                  immutability = 1;
                  lastScreen = 2;
                  location = 0;
                  plugin = "org.kde.plasma.folder";
                  wallpaperplugin = "org.kde.image";
                  Wallpaper."org.kde.image".General = {
                    Image = wallpaper;
                  };
                };
                "4" = {
                  activityId = "c2b12168-8128-4075-8bce-38fb70b77c7a";
                  formfactor = 0;
                  immutability = 1;
                  lastScreen = 3;
                  location = 0;
                  plugin = "org.kde.plasma.folder";
                  wallpaperplugin = "org.kde.image";
                  Wallpaper."org.kde.image".General = {
                    Image = wallpaper;
                  };
                };
                "5" = {
                  activityId = "c2b12168-8128-4075-8bce-38fb70b77c7a";
                  formfactor = 0;
                  immutability = 1;
                  lastScreen = 4;
                  location = 0;
                  plugin = "org.kde.plasma.folder";
                  wallpaperplugin = "org.kde.image";
                  Wallpaper."org.kde.image".General = {
                    Image = wallpaper;
                  };
                };
                # Panels and applets
                "100" = {
                  activityId = "";
                  formfactor = 2;
                  immutability = 1;
                  lastScreen = 0;
                  location = 4;
                  plugin = "org.kde.panel";
                  wallpaperplugin = "org.kde.image";
                  Applets = {
                    "101" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.cpucore";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.barchart";
                          title = "Individual Core Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"cpu/cpu.*/usage\"]";
                          totalSensors = "[\"cpu/all/usage\"]";
                        };
                      };
                    };
                    "102" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.memory";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.piechart";
                          title = "Memory Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"memory/physical/used\"]";
                          lowPrioritySensorIds = "[\"memory/physical/total\"]";
                          totalSensors = "[\"memory/physical/usedPercent\"]";
                        };
                      };
                    };
                    "103" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "104" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.kickoff";
                      Configuration = {
                        popupHeight = 493;
                        popupWidth = 633;
                        General = {
                          favoritesPortedToKAstats = true;
                          icon = "app-launcher";
                        };
                      };
                    };
                    "105" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.pager";
                    };
                    "106" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.marginsseparator";
                    };
                    "107" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.icontasks";
                    };
                    "108" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "109" = {
                      activityId = "";
                      formfactor = 0;
                      immutability = 1;
                      lastScreen = -1;
                      location = 0;
                      plugin = "org.kde.plasma.systemtray";
                      popupHeight = 432;
                      popupWidth = 432;
                      wallpaperplugin = "org.kde.image";
                      General = {
                        extraItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather,org.kde.plasma.battery";
                        knownItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather";
                        shownItems = "org.kde.plasma.battery";
                      };
                      Applets = {
                        "10901" = {
                          immutability = 1;
                          plugin = "org.kde.kdeconnect";
                        };
                        "10902" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.cameraindicator";
                        };
                        "10903" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.clipboard";
                        };
                        "10904" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.devicenotifier";
                        };
                        "10905" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.manage-inputmethod";
                        };
                        "10906" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.notifications";
                        };
                        "10907" = {
                          immutability = 1;
                          plugin = "org.kde.kscreen";
                        };
                        "10908" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardindicator";
                        };
                        "10909" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardlayout";
                        };
                        "10910" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.networkmanagement";
                        };
                        "10911" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.printmanager";
                        };
                        "10912" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.volume";
                          Configuration.General = {
                            migrated = true;
                          };
                        };
                        "10913" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.weather";
                        };
                        "10914" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.brightness";
                        };
                        "10915" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.battery";
                        };
                        "10916" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.bluetooth";
                        };
                      };
                    };
                    "110" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.digitalclock";
                      Configuration = {
                        popupHeight = 375;
                        popupWidth = 525;
                      };
                    };
                    "111" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.showdesktop";
                    };
                  };
                  General = {
                    AppletOrder = "101;102;103;104;105;106;107;108;109;110;111";
                  };
                };
                "200" = {
                  activityId = "";
                  formfactor = 2;
                  immutability = 1;
                  lastScreen = 1;
                  location = 4;
                  plugin = "org.kde.panel";
                  wallpaperplugin = "org.kde.image";
                  Applets = {
                    "201" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.cpucore";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.barchart";
                          title = "Individual Core Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"cpu/cpu.*/usage\"]";
                          totalSensors = "[\"cpu/all/usage\"]";
                        };
                      };
                    };
                    "202" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.memory";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.piechart";
                          title = "Memory Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"memory/physical/used\"]";
                          lowPrioritySensorIds = "[\"memory/physical/total\"]";
                          totalSensors = "[\"memory/physical/usedPercent\"]";
                        };
                      };
                    };
                    "203" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "204" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.kickoff";
                      Configuration = {
                        popupHeight = 493;
                        popupWidth = 633;
                        General = {
                          favoritesPortedToKAstats = true;
                          icon = "app-launcher";
                        };
                      };
                    };
                    "205" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.pager";
                    };
                    "206" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.marginsseparator";
                    };
                    "207" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.icontasks";
                    };
                    "208" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "209" = {
                      activityId = "";
                      formfactor = 0;
                      immutability = 1;
                      lastScreen = -1;
                      location = 0;
                      plugin = "org.kde.plasma.systemtray";
                      popupHeight = 432;
                      popupWidth = 432;
                      wallpaperplugin = "org.kde.image";
                      General = {
                        extraItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather,org.kde.plasma.battery";
                        knownItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather";
                        shownItems = "org.kde.plasma.battery";
                      };
                      Applets = {
                        "20901" = {
                          immutability = 1;
                          plugin = "org.kde.kdeconnect";
                        };
                        "20902" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.cameraindicator";
                        };
                        "20903" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.clipboard";
                        };
                        "20904" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.devicenotifier";
                        };
                        "20905" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.manage-inputmethod";
                        };
                        "20906" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.notifications";
                        };
                        "20907" = {
                          immutability = 1;
                          plugin = "org.kde.kscreen";
                        };
                        "20908" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardindicator";
                        };
                        "20909" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardlayout";
                        };
                        "20910" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.networkmanagement";
                        };
                        "20911" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.printmanager";
                        };
                        "20912" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.volume";
                          Configuration.General = {
                            migrated = true;
                          };
                        };
                        "20913" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.weather";
                        };
                        "20914" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.brightness";
                        };
                        "20915" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.battery";
                        };
                        "20916" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.bluetooth";
                        };
                      };
                    };
                    "210" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.digitalclock";
                      Configuration = {
                        popupHeight = 375;
                        popupWidth = 525;
                      };
                    };
                    "211" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.showdesktop";
                    };
                  };
                  General = {
                    AppletOrder = "201;202;203;204;205;206;207;208;209;210;211";
                  };
                };
                "300" = {
                  activityId = "";
                  formfactor = 2;
                  immutability = 1;
                  lastScreen = 2;
                  location = 4;
                  plugin = "org.kde.panel";
                  wallpaperplugin = "org.kde.image";
                  Applets = {
                    "301" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.cpucore";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.barchart";
                          title = "Individual Core Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"cpu/cpu.*/usage\"]";
                          totalSensors = "[\"cpu/all/usage\"]";
                        };
                      };
                    };
                    "302" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.memory";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.piechart";
                          title = "Memory Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"memory/physical/used\"]";
                          lowPrioritySensorIds = "[\"memory/physical/total\"]";
                          totalSensors = "[\"memory/physical/usedPercent\"]";
                        };
                      };
                    };
                    "303" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "304" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.kickoff";
                      Configuration = {
                        popupHeight = 493;
                        popupWidth = 633;
                        General = {
                          favoritesPortedToKAstats = true;
                          icon = "app-launcher";
                        };
                      };
                    };
                    "305" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.pager";
                    };
                    "306" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.marginsseparator";
                    };
                    "307" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.icontasks";
                    };
                    "308" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "309" = {
                      activityId = "";
                      formfactor = 0;
                      immutability = 1;
                      lastScreen = -1;
                      location = 0;
                      plugin = "org.kde.plasma.systemtray";
                      popupHeight = 432;
                      popupWidth = 432;
                      wallpaperplugin = "org.kde.image";
                      General = {
                        extraItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather,org.kde.plasma.battery";
                        knownItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather";
                        shownItems = "org.kde.plasma.battery";
                      };
                      Applets = {
                        "30901" = {
                          immutability = 1;
                          plugin = "org.kde.kdeconnect";
                        };
                        "30902" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.cameraindicator";
                        };
                        "30903" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.clipboard";
                        };
                        "30904" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.devicenotifier";
                        };
                        "30905" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.manage-inputmethod";
                        };
                        "30906" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.notifications";
                        };
                        "30907" = {
                          immutability = 1;
                          plugin = "org.kde.kscreen";
                        };
                        "30908" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardindicator";
                        };
                        "30909" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardlayout";
                        };
                        "30910" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.networkmanagement";
                        };
                        "30911" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.printmanager";
                        };
                        "30912" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.volume";
                          Configuration.General = {
                            migrated = true;
                          };
                        };
                        "30913" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.weather";
                        };
                        "30914" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.brightness";
                        };
                        "30915" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.battery";
                        };
                        "30916" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.bluetooth";
                        };
                      };
                    };
                    "310" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.digitalclock";
                      Configuration = {
                        popupHeight = 375;
                        popupWidth = 525;
                      };
                    };
                    "311" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.showdesktop";
                    };
                  };
                  General = {
                    AppletOrder = "301;302;303;304;305;306;307;308;309;310;311";
                  };
                };
                "400" = {
                  activityId = "";
                  formfactor = 2;
                  immutability = 1;
                  lastScreen = 3;
                  location = 4;
                  plugin = "org.kde.panel";
                  wallpaperplugin = "org.kde.image";
                  Applets = {
                    "401" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.cpucore";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.barchart";
                          title = "Individual Core Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"cpu/cpu.*/usage\"]";
                          totalSensors = "[\"cpu/all/usage\"]";
                        };
                      };
                    };
                    "402" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.memory";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.piechart";
                          title = "Memory Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"memory/physical/used\"]";
                          lowPrioritySensorIds = "[\"memory/physical/total\"]";
                          totalSensors = "[\"memory/physical/usedPercent\"]";
                        };
                      };
                    };
                    "403" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "404" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.kickoff";
                      Configuration = {
                        popupHeight = 493;
                        popupWidth = 633;
                        General = {
                          favoritesPortedToKAstats = true;
                          icon = "app-launcher";
                        };
                      };
                    };
                    "405" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.pager";
                    };
                    "406" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.marginsseparator";
                    };
                    "407" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.icontasks";
                    };
                    "408" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "409" = {
                      activityId = "";
                      formfactor = 0;
                      immutability = 1;
                      lastScreen = -1;
                      location = 0;
                      plugin = "org.kde.plasma.systemtray";
                      popupHeight = 432;
                      popupWidth = 432;
                      wallpaperplugin = "org.kde.image";
                      General = {
                        extraItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather,org.kde.plasma.battery";
                        knownItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather";
                        shownItems = "org.kde.plasma.battery";
                      };
                      Applets = {
                        "40901" = {
                          immutability = 1;
                          plugin = "org.kde.kdeconnect";
                        };
                        "40902" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.cameraindicator";
                        };
                        "40903" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.clipboard";
                        };
                        "40904" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.devicenotifier";
                        };
                        "40905" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.manage-inputmethod";
                        };
                        "40906" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.notifications";
                        };
                        "40907" = {
                          immutability = 1;
                          plugin = "org.kde.kscreen";
                        };
                        "40908" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardindicator";
                        };
                        "40909" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardlayout";
                        };
                        "40910" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.networkmanagement";
                        };
                        "40911" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.printmanager";
                        };
                        "40912" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.volume";
                          Configuration.General = {
                            migrated = true;
                          };
                        };
                        "40913" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.weather";
                        };
                        "40914" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.brightness";
                        };
                        "40915" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.battery";
                        };
                        "40916" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.bluetooth";
                        };
                      };
                    };
                    "410" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.digitalclock";
                      Configuration = {
                        popupHeight = 375;
                        popupWidth = 525;
                      };
                    };
                    "411" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.showdesktop";
                    };
                  };
                  General = {
                    AppletOrder = "401;402;403;404;405;406;407;408;409;410;411";
                  };
                };
                "500" = {
                  activityId = "";
                  formfactor = 2;
                  immutability = 1;
                  lastScreen = 4;
                  location = 4;
                  plugin = "org.kde.panel";
                  wallpaperplugin = "org.kde.image";
                  Applets = {
                    "501" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.cpucore";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.barchart";
                          title = "Individual Core Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"cpu/cpu.*/usage\"]";
                          totalSensors = "[\"cpu/all/usage\"]";
                        };
                      };
                    };
                    "502" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.systemmonitor.memory";
                      Configuration = {
                        CurrentPreset = "org.kde.plasma.systemmonitor";
                        popupHeight = 375;
                        popupWidth = 525;
                        Appearance = {
                          chartFace = "org.kde.ksysguard.piechart";
                          title = "Memory Usage";
                        };
                        Sensors = {
                          highPrioritySensorIds = "[\"memory/physical/used\"]";
                          lowPrioritySensorIds = "[\"memory/physical/total\"]";
                          totalSensors = "[\"memory/physical/usedPercent\"]";
                        };
                      };
                    };
                    "503" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "504" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.kickoff";
                      Configuration = {
                        popupHeight = 493;
                        popupWidth = 633;
                        General = {
                          favoritesPortedToKAstats = true;
                          icon = "app-launcher";
                        };
                      };
                    };
                    "505" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.pager";
                    };
                    "506" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.marginsseparator";
                    };
                    "507" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.icontasks";
                    };
                    "508" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.panelspacer";
                    };
                    "509" = {
                      activityId = "";
                      formfactor = 0;
                      immutability = 1;
                      lastScreen = -1;
                      location = 0;
                      plugin = "org.kde.plasma.systemtray";
                      popupHeight = 432;
                      popupWidth = 432;
                      wallpaperplugin = "org.kde.image";
                      General = {
                        extraItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather,org.kde.plasma.battery";
                        knownItems = "org.kde.kdeconnect,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.notifications,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.networkmanagement,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather";
                        shownItems = "org.kde.plasma.battery";
                      };
                      Applets = {
                        "50901" = {
                          immutability = 1;
                          plugin = "org.kde.kdeconnect";
                        };
                        "50902" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.cameraindicator";
                        };
                        "50903" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.clipboard";
                        };
                        "50904" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.devicenotifier";
                        };
                        "50905" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.manage-inputmethod";
                        };
                        "50906" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.notifications";
                        };
                        "50907" = {
                          immutability = 1;
                          plugin = "org.kde.kscreen";
                        };
                        "50908" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardindicator";
                        };
                        "50909" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.keyboardlayout";
                        };
                        "50910" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.networkmanagement";
                        };
                        "50911" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.printmanager";
                        };
                        "50912" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.volume";
                          Configuration.General = {
                            migrated = true;
                          };
                        };
                        "50913" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.weather";
                        };
                        "50914" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.brightness";
                        };
                        "50915" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.battery";
                        };
                        "50916" = {
                          immutability = 1;
                          plugin = "org.kde.plasma.bluetooth";
                        };
                      };
                    };
                    "510" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.digitalclock";
                      Configuration = {
                        popupHeight = 375;
                        popupWidth = 525;
                      };
                    };
                    "511" = {
                      immutability = 1;
                      plugin = "org.kde.plasma.showdesktop";
                    };
                  };
                  General = {
                    AppletOrder = "501;502;503;504;505;506;507;508;509;510;511";
                  };
                };
              };
            };
          };
        }
      ];
    };
}
