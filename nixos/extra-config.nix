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
        browsing = true;
        browsedConf = ''
          # Enable automatic queue creation for all IPP printers
          CreateIPPPrinterQueues All
          CreateRemoteCUPSPrinterQueues Yes
          
          # Use DNS-SD for discovery (both USB and WiFi)
          BrowseRemoteProtocols dnssd
          BrowseInterval 10  # Faster discovery
          
          # Auto-create queues without PPD files (driverless printing)
          IPPPrinterQueueType NoPPD
          
          # Allow immediate printing without manual acceptance
          NewIPPPrinterQueuesShared Yes
          AllowResharingRemoteCUPSPrinters Yes
        '';
        
        # Configure cupsd.conf settings
        extraConf = ''
          Browsing On
          DefaultShared Yes
          BrowseDNSSDSubTypes _cups,_print
          BrowseLocalProtocols dnssd
          BrowseRemoteProtocols dnssd
          
          # Auto-purge completed jobs
          AutoPurgeJobs Yes
          
          # Allow all clients to print
          <Location />
            Order allow,deny
            Allow all
          </Location>
          
          # Enable web interface for debugging (optional)
          WebInterface Yes
        '';
    };

    services.avahi = {
        enable    = true;
        nssmdns4  = true;
        nssmdns6  = true;
        openFirewall = true;   # open UDP 5353 for discovery :contentReference[oaicite:1]{index=1}
    };

    services.ipp-usb.enable = true;  # ipp-usb daemon :contentReference[oaicite:2]{index=2}

    hardware.printers = { ensurePrinters = []; };
    hardware.enableRedistributableFirmware = true;

    # bluetooth
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    services.blueman.enable = true;

    networking.firewall.enable = true;
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Zurich";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    system.stateVersion = "25.05";
}
