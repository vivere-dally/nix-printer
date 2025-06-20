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
        cups-filters
        brotli
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
[settings]
    dir = /home/aico-printnode/.printnode
    dir_create = yes
[gui]
    headless = yes
[process]
    shutdown_on_sigint = yes
[network]
[proxy]
[computer]
[development]
        '';
    };

    # Print utils
    services.printing = {
    enable        = true;  # start CUPS
    openFirewall  = true;  # open TCP 631 for IPP :contentReference[oaicite:0]{index=0}
    # include common driver packages; add more as needed
    # drivers = with pkgs; [
    #   gutenprint             # generic drivers
    #   hplip                  # HP printers
    #   hplipWithPlugin        # HP with proprietary plugin (requires unfree)
    #   splix                  # Samsung SPL
    #   brlaser                # Brother
    #   brgenml1lpr            # Brother LPR backend
    #   brgenml1cupswrapper    # Brother CUPS wrapper
    #   epson-escpr2           # Epson AirPrint
    #   cnijfilter2            # Canon Pixma
    # ];
  };

    services.avahi = {
    enable    = true;
    nssmdns4  = true;
    nssmdns6  = true;
    openFirewall = true;   # open UDP 5353 for discovery :contentReference[oaicite:1]{index=1}
    };

  # Turn any USB "IPP‑Everywhere" printer into a network printer
  services.ipp-usb.enable = true;  # ipp-usb daemon :contentReference[oaicite:2]{index=2}

  hardware.printers = {
    ensurePrinters = [];  # leave empty
  };

    hardware.enableRedistributableFirmware = true;

    networking.firewall.enable = true;
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Zurich";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    system.stateVersion = "25.05";
}
