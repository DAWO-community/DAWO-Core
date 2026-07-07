{
  # Audio (PipeWire). ON by default: every workplace laptop needs sound, and it
  # must NOT depend on the desktop. Plasma6 enables PipeWire via nixpkgs mkDefault,
  # but GNOME does not - so a GNOME host shipped with no audio server (silent
  # laptop). This block makes PipeWire the DE-agnostic baseline. FOSS all the way
  # (PipeWire + WirePlumber), no PulseAudio daemon.
  flake.modules.nixos.services-audio =
    { config, lib, ... }:
    let
      cfg = config.dawo.audio;
    in
    {
      options.dawo.audio = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "PipeWire audio (ALSA + PulseAudio compat). On by default; a host may disable it.";
        };
      };

      config = lib.mkIf cfg.enable {
        # PipeWire replaces PulseAudio; the compat layer keeps pulse clients working.
        services.pulseaudio.enable = lib.mkForce false;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
        # rtkit lets PipeWire acquire realtime priority (glitch-free audio).
        security.rtkit.enable = true;
      };
    };
}
