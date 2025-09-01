{ pkgs, ... }:

{
  systemd.user.services.pipewire = {
    Unit = {
      Description = "PipeWire Multimedia Service";
      After = [ "graphical-session-pre.target" ];
      Wants = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${pkgs.pipewire}/bin/pipewire";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.pipewirePulse = {
    Unit = {
      Description = "PipeWire PulseAudio";
      After = [ "pipewire.service" ];
      Wants = [ "pipewire.service" ];
    };
    Service = {
      ExecStart = "${pkgs.pipewire}/bin/pipewire-pulse";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.wireplumber = {
    Unit = {
      Description = "PipeWire Session Manager";
      After = [ "pipewire.service" ];
      Wants = [ "pipewire.service" ];
    };
    Service = {
      ExecStart = "${pkgs.wireplumber}/bin/wireplumber";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

