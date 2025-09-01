{ config, lib, pkgs, ... }:

{
  imports = [
    (import ./audio { inherit pkgs; })
    (import ./gpg-agent { inherit pkgs; })
  ];
}
