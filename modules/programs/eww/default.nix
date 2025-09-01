{ config, lib, pkgs, ... }:

let
  widgetsSrc = ./bar;
  ewwWayland = pkgs.callPackage ./eww-wayland.nix {
    widgets = widgetsSrc;
  };
in
  {
  programs.eww = {
    enable = true;
    package = ewwWayland;
    enableZshIntegration = true;
  };

  home.file.".local/bin/eww" = {
    source = "${ewwWayland}/bin/eww";
  };

  home.file.".config/eww" = {
    source = "${ewwWayland}/share/eww";
    recursive = true;
  };

  systemd.user.services.eww = {
    Unit = {
      Description = "Eww Wayland Daemon";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${ewwWayland}/bin/eww -c ${config.xdg.configHome}/eww daemon";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
