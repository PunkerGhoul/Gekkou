{ pkgs, ... }:

{
  imports = [
    (import ./nixpkgs { inherit pkgs; })
    ./networking.nix
  ];
}
