{ config, lib, pkgs, ... }:

let
  ewwWayland = pkgs.callPackage ./eww-wayland.nix { };
  
  # Detectar automáticamente todos los scripts en la carpeta scripts/
  scriptsDir = ./bar/scripts;
  scriptFiles = builtins.attrNames (builtins.readDir scriptsDir);
  
  # Función para crear la configuración de un script
  makeScriptConfig = scriptName: {
    name = ".config/eww/scripts/${scriptName}";
    value = {
      text = builtins.readFile (scriptsDir + "/${scriptName}");
      executable = true;
    };
  };
  
  # Generar configuraciones para todos los scripts
  scriptConfigs = builtins.listToAttrs (map makeScriptConfig scriptFiles);
  
  # Función para copiar archivos individuales (no recursivo)
  makeFileConfig = fileName: fileType: {
    name = ".config/eww/${fileName}";
    value = {
      source = ./bar + "/${fileName}";
    };
  };
  
  # Lista de archivos principales a copiar
  mainFiles = [
    "eww.yuck"
    "eww.scss" 
    "launch_bar"
  ];
  
  # Generar configuraciones para archivos principales
  fileConfigs = builtins.listToAttrs (map (f: makeFileConfig f "file") mainFiles);
in
{
  programs.eww = {
    enable = true;
    package = ewwWayland;
    enableZshIntegration = true;
  };

  home.file = {
    ".local/bin/eww" = {
      source = "${ewwWayland}/bin/eww";
    };

    # Copiar carpeta de imágenes si existe
    ".config/eww/images" = {
      source = ./bar/images;
      recursive = true;
    };
  } // fileConfigs // scriptConfigs;

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
