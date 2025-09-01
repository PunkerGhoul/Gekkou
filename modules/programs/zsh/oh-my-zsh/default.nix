{ pkgs, ... }:

{
  oh-my-zsh = {
    enable = true;
    plugins = [
      "git"
      "command-not-found"
      "archlinux"
      "debian"
      "extract"
      "fzf"
      "nmap"
      "python"
    ];
    extraConfig = ''
      zstyle ':omz:update' mode reminder
    '';
  };
}

