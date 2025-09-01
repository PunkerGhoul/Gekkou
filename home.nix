{ config, lib, pkgs, nixgl, username, ... }:


let
  env = import ./env.nix;
  #nixGLPatched = pkgs.nixgl.auto.nixGLDefault.overrideAttrs (old: {
  #  postPatch = (old.postPatch or "") + ''
  #    substituteInPlace nixGL.nix \
  #      --replace "mesa.drivers" "mesa"
  #  '';
  #});

  #nixgl = import nixGLPatched { inherit pkgs; };
in {
  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
  };
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    at-spi2-atk
    fontconfig
    git
    mesa
    mesa-demos
    meslo-lgs-nf
    nerd-fonts.hack
    noto-fonts
    noto-fonts-color-emoji
    python313
    pavucontrol
    kdePackages.dolphin
    zap
    zip
    playerctl
    brightnessctl
    networkmanager
    jq
    curl
    alsa-utils
    socat
    hyprpaper
    libva-utils
    pamixer
    wireplumber
    htop
    
    # Códecs multimedia para LibreWolf
    ffmpeg-full
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    ".hushlogin".text = "";

    # LibreWolf
    ## Personal profile
    ".local/bin/librewolf-personal" = {
      text = ''
      #!${pkgs.bash}/bin/bash
        ${pkgs.librewolf}/bin/librewolf -P "Personal" "$@"
      '';
      executable = true;
    };
    ## Pentesting profile
    ".local/bin/librewolf-pentesting" = {
      text = ''
      #!${pkgs.bash}/bin/bash
        ${pkgs.librewolf}/bin/librewolf  -P "Pentesting" "$@"
      '';
      executable = true;
    };
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/arch/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
    hinting = "none";
    defaultFonts = {
      monospace = [ "Hack Nerd Font Mono" "MesloLGS NF" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  imports = [
    (import ./modules { inherit config lib pkgs env; })
  ];
}
