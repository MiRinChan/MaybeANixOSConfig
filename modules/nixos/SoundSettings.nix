{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    pulseaudio # 提供 `pactl` 在某些应用需要 (如 sonic-pi)
  ];

  # PipeWire is a new low-level multimedia framework.
  # It aims to offer capture and playback for both audio and video with minimal latency.
  # It support for PulseAudio-, JACK-, ALSA- and GStreamer-based applications.
  # PipeWire has a great bluetooth support, it can be a good alternative to PulseAudio.
  #     https://nixos.wiki/wiki/PipeWire
  services.pipewire = {
    enable = true;
    package = pkgs.pipewire;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/scripts/52-usb-dac.lua" ''
          rule = {
            matches = {
              {
                { "node.nick", "equals", "MOONDROP Dawn Pro" },
              },
            },
            apply_properties = {
              ["audio.format"] = "s32le",
              ["audio.rate"] = 384000,
            },
          }

          table.insert(alsa_monitor.rules, rule)
        '')
      ];
    };
    extraConfig = {
      # set sample rates by `pw-metadata -n settings 0 clock.force-rate 192000`
      # make default by `pw-metadata -n settings 0 clock.force-rate 0`
      # i dont know why it wont setted.

      pipewire = {
        "98-sample-rates" = {
          "context.properties" = {
            "default.clock.rate" = 192000;
            "default.clock.allowed-rates" = [44100 48000 96000 192000 384000];
            "default.clock.quantum" = 1024;
            "default.clock.min-quantum" = 32;
            # Can't be set too low with my devices unfortunately
            "default.clock.max-quantum" = 8192;
          };
        };
      };
    };
  };
  # 低延迟
  security.rtkit.enable = true;
  # 禁用 pulseaudio，与 pipewire 冲突
  hardware.pulseaudio.enable = false;

  environment.etc."share/wireplumber/scripts/52-usb-dac.lua" = {
    text = ''
      rule = {
        matches = {
          {
            { "node.nick", "equals", "MOONDROP Dawn Pro" },
          },
        },
        apply_properties = {
          ["audio.format"] = "s32le",
          ["audio.rate"] = 384000,
        },
      }

      table.insert(alsa_monitor.rules, rule)
    '';
  };

  systemd.services.easyeffects.serviceConfig.TimeoutSec = "5"; # Prevent wating for long time.
}
