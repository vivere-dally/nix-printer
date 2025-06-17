{
    description = "Aiconomy AG NixOS for RaspberryPi Print Nodes";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
        nixos-generators = {
            url = "github:nix-community/nixos-generators";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, nixos-generators, ... }: let
        system = "aarch64-linux";
        baseModules = [
            ({ config, pkgs, ... }: {
                disabledModules = [ "profiles/base.nix" ];
                system.stateVersion = "25.05";
            })
            ({ config, pkgs, ... }: {
                users.users.admin = {
                    password = "admin1234";
                    isNormalUser = true;
                    extraGroups = [ "wheel" ];
                };
            })
            ./extra-config.nix
        ];
        in {
        nixosConfigurations.raspberrypi = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = baseModules;
        };

        packages.${system} = {
            sdcard = nixos-generators.nixosGenerate {
                inherit system;
                format = "sd-aarch64";
                modules = baseModules;
            };
        };
    };
}
