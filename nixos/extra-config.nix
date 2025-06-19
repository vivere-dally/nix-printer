{ config, pkgs, lib, ... }:
{
    imports = [ ./print-node-module.nix ];

    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs; [
        vim
        wget
        git
        gzip
        libcap
        zlib
        zstd
        libgcc
        binutils
        nix-ld
        networkmanager
        cups
        print-node
    ];
    programs.nix-ld.enable = true;

    nixpkgs.config.packageOverrides = pkgs: {
        print-node = pkgs.callPackage ./print-node.nix { };
    };
    services.print-node = {
        enable = true;
        config = ''
[credentials]
    email = d.groza@aico.swiss
    password = Aico2025
        '';
    };

    # Print utils
    services.printing.enable = true;
    services.cups = {
      enable = true;
      allowUserFromAnyGroup = true;
      extraGroups = [ "lp" "scanner" ];
    };
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    hardware.enableRedistributableFirmware = true;

    networking.firewall.enable = true;
    networking.networkmanager.enable = true;
    networking.wireless.networks = {
        "DIGI-tnV4" = {
            psk = "yUPaJEkH3a";

        };
    };

    time.timeZone = "Europe/Zurich";

    users.users.aico-print = {
        isNormalUser = true;
        extraGroups = [ "wheel" "lp" "scanner" ];
    };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    system.stateVersion = "25.05";
}
