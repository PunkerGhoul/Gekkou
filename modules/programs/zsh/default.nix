{ config, pkgs, ...}:

let
  ohMyZshConfig = import ./oh-my-zsh { inherit pkgs; };
  pluginsList = import ./plugins { inherit pkgs; };
in {
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    envExtra = ''
      export GPG_TTY=$(tty)
      export GOPATH=$HOME/.go
      export PATH="$PATH:$GOPATH/bin"
      export PATH="$PATH:$HOME/Documents/Tools"
      export PATH="$PATH:$HOME/.local/bin"
      export FZF_BASE="${pkgs.fzf}/share/fzf"
    '';
    shellAliases = {
      ipfuscate = ''
        function _ipfuscate() { python3 /opt/IPFuscator/ipfuscator.py "$1" | awk -F "\t" "/IP Address:/,0 {if (\$2 && \$2 !~ /:$| \$/) {gsub(\" \", \"\t\", \$2); print \$2}}"; }; _ipfuscate;
      '';
    };
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    inherit (ohMyZshConfig) oh-my-zsh;
    inherit (pluginsList) plugins;
  };
}
