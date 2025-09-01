{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = (config.lib.nixGL.wrap pkgs.hyprland);
    portalPackage = (config.lib.nixGL.wrap pkgs.xdg-desktop-portal-hyprland);
    settings = {
      # Refer to the wiki for more information
      # https://wiki.hypr.land/Configuration/

      ## Monitors
      monitor = ",1920x1080@60,auto,auto";

      ## My Programs
      ### https://wiki.hypr.land/Configuring/Keywords/
      "$terminal" = "kitty";
      "$filemanager" = "dolphin";
      "$menu" = "wofi --show=drun -a";

      ## Look and Feel
      ### https://wiki.hypr.land/Configuring/Variables/
      #### https://wiki.hypr.land/Configuring/Variables/#general
      general = {
        gaps_in = 5;
        gaps_out = 20;

        border_size = 2;

        #### https://wiki.hypr.land/Configuring/Variables/#variables-types
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        #### Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false;

        #### https://wiki.hypr.land/Configuring/Tearing/
        allow_tearing = true;

        layout = "dwindle";
      };

      #### https://wiki.hypr.land/Configuring/Variables/#decoration
      decoration = {
        rounding = 10;
        rounding_power = 2;

        #### Change transparency of focused and unfocused windows
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        #### https://wiki.hypr.land/Configuring/Variables/#blur
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      ## Dwindle Layout 
      ### https://wiki.hypr.land/Configuring/Dwindle-Layout/
      dwindle = {
        #### Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        pseudotile = true;
        #### You probably want this
        preserve_split = true;
      };

      ## Master Layout
      ### https://wiki.hypr.land/Configuring/Master-Layout/
      master = {
        new_status = "master";
      };

      ## Misc
      ### https://wiki.hypr.land/Configuring/Variables/#misc
      misc = {
        force_default_wallpaper = -1; # Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = false;  # If true disables the random hyprland logo / anime girl background. :(
      };

      ## Input
      ### https://wiki.hypr.land/Configuring/Variables/#input
      input = {
        kb_layout = "latam";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        follow_mouse = 1;

        sensitivity = 0;  # -1.0 - 1.0, 0 means no modification.

        touchpad = {
          natural_scroll = false;
        };
      };

      ### Example per-device config
      #### https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs
      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      ### Cursor
      cursor = {
        no_hardware_cursors = false;
      };

      ## Keybindings
      ### https://wiki.hypr.land/Configuring/Keywords/
      "$mainMod" = "SUPER"; # Sets "Windows" key as main modifier
    };
    extraConfig = builtins.readFile ./hyprland.conf;
    systemd.enableXdgAutostart = true;
  };
}
