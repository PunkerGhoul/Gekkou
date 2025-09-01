{ pkgs, ... }:

{
  imports = [
    (import ./nixpkgs { inherit pkgs; })
  ];
}
