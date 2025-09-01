{ config, lib, pkgs, ... }:

let
  rofiWayland = pkgs.callPackage ./rofi-wayland.nix { };
in
{
  programs.rofi = {
    enable = true;
    package = rofiWayland;
    terminal = "${pkgs.kitty}/bin/kitty";
    
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      display-drun = "Apps";
      display-run = "Run";
      display-window = "Window";
      drun-display-format = "{name}";
      window-format = "{w} · {c} · {t}";
      font = "Hack Nerd Font 10";
      icon-theme = "Papirus-Dark";
    };
    
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        bg0 = mkLiteral "#1e1e2e";
        bg1 = mkLiteral "#313244";
        bg2 = mkLiteral "#45475a";
        fg0 = mkLiteral "#cdd6f4";
        fg1 = mkLiteral "#bac2de";
        accent = mkLiteral "#b4befe";
        urgent = mkLiteral "#f38ba8";
        
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg0";
        
        margin = 0;
        padding = 0;
        spacing = 0;
      };
      
      window = {
        background-color = mkLiteral "@bg0";
        location = mkLiteral "center";
        width = 640;
        border-radius = 12;
        border = 2;
        border-color = mkLiteral "@accent";
      };
      
      inputbar = {
        font = "Hack Nerd Font 12";
        padding = mkLiteral "12px";
        spacing = mkLiteral "12px";
        children = mkLiteral "[ icon-search, entry ]";
        background-color = mkLiteral "@bg1";
      };
      
      icon-search = {
        expand = false;
        filename = "search";
        size = 28;
      };
      
      entry = {
        placeholder = "Search";
        placeholder-color = mkLiteral "@fg1";
      };
      
      message = {
        margin = mkLiteral "12px 0 0";
        border-radius = 8;
        border-color = mkLiteral "@accent";
        background-color = mkLiteral "@bg1";
      };
      
      textbox = {
        padding = mkLiteral "8px 12px";
      };
      
      listview = {
        background-color = mkLiteral "transparent";
        margin = mkLiteral "12px 0 0";
        lines = 8;
        columns = 1;
        fixed-height = false;
        scrollbar = true;
      };
      
      scrollbar = {
        width = 4;
        border = 0;
        handle-color = mkLiteral "@accent";
        handle-width = 4;
        padding = 0;
      };
      
      element = {
        padding = mkLiteral "8px 12px";
        spacing = mkLiteral "12px";
        border-radius = 8;
      };
      
      "element normal normal" = {
        background-color = mkLiteral "inherit";
        text-color = mkLiteral "inherit";
      };
      
      "element normal urgent" = {
        background-color = mkLiteral "@urgent";
        text-color = mkLiteral "@bg0";
      };
      
      "element normal active" = {
        background-color = mkLiteral "@accent";
        text-color = mkLiteral "@bg0";
      };
      
      "element selected normal" = {
        background-color = mkLiteral "@bg2";
      };
      
      "element selected urgent" = {
        background-color = mkLiteral "@urgent";
        text-color = mkLiteral "@bg0";
      };
      
      "element selected active" = {
        background-color = mkLiteral "@accent";
        text-color = mkLiteral "@bg0";
      };
      
      "element-icon" = {
        size = 32;
        vertical-align = mkLiteral "0.5";
      };
      
      "element-text" = {
        text-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };
    };
  };
}
