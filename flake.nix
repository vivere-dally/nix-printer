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
  {
    nixosModules = {
      system = {
        disabledModules = [
          "profiles/base.nix"
        ];

        system.stateVersion = "25.05";
      };  
      users = {
        users.users = {
          admin = {
            password = "admin1234";
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        };
      };  
    };  

    packages.aarch64-linux = {
      sdcard = 
        let 
          crossPkgs = import nixpkgs {
            system      = "aarch64-linux";
            crossSystem = { config = "aarch64-linux"; };
          };
        in
        nixos-generators.nixosGenerate {
          system = "aarch64-linux";
          format = "sd-aarch64";
          modules = [
            ./extra-config.nix
            self.nixosModules.system
            self.nixosModules.users
          ];
        };
    };
  };
}
