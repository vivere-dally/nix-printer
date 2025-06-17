{
  description = "Base Raspberry Pi Zero 2 W";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
  let
    # System-specific configurations
    systems = {
      x86_64-linux = "x86_64-linux";
      aarch64-linux = "aarch64-linux";
    };
    # Cross-compilation setup for x86_64 -> aarch64
    pkgsCross = pkgs: pkgs.pkgsCross.aarch64-multiplatform;
  in {
    nixosModules = {
      system = {
        disabledModules = [ "profiles/base.nix" ];
        system.stateVersion = "25.05";
      };
      users = {
        users.users.admin = {
          password = "admin1234";
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
      };
    };

    # Build for x86_64 host with cross-compilation
    packages.x86_64-linux.sdcard = let
      pkgs = import nixpkgs {
        system = systems.x86_64-linux;
        config.allowUnsupportedSystem = true;
      };
    in nixos-generators.nixosGenerate {
      pkgs = pkgsCross pkgs;  # Cross-compile to aarch64
      format = "sd-aarch64";
      modules = [
        ./extra-config.nix
        self.nixosModules.system
        self.nixosModules.users
      ];
    };
  };
}
