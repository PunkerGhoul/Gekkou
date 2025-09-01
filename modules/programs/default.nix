{ config, lib, pkgs, env, ... }:

{
  imports = [
    (import ./eww { inherit config lib pkgs; })
    (import ./kitty { inherit config pkgs; })
    (import ./zsh { inherit config pkgs; })
    (import ./fzf { inherit pkgs; })
    (import ./git { inherit pkgs env; })
    (import ./bat { inherit pkgs; })
    (import ./jq { inherit pkgs; })
    (import ./neovim { inherit pkgs; })
    (import ./librewolf { inherit config pkgs; })
    (import ./rofi { inherit config lib pkgs; })
  ];
}
