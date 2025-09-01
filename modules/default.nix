{ config, lib, pkgs, env, ... }:

{
  imports = [
    (import ./services { inherit config lib pkgs; })
    (import ./wayland { inherit config pkgs; })
    (import ./programs { inherit config lib pkgs env; })
  ];
}
