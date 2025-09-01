{
  description = "Home Manager configuration of USERNAME_VAR";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl.url = "github:guibou/nixGL";
  };

  outputs =
    { nixpkgs, home-manager, nixgl, ... }:
    let
      system = "ARCHITECTURE_VAR";
      overlays = [
        nixgl.overlay
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
      username = "USERNAME_VAR";
    in
    {
      homeConfigurations."USERNAME_VAR" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./configuration
          ./home.nix
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          inherit nixgl username;
        };
      };
    };
}
