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
    # browsing = true;
    browsedConf = ''
      # cups-browsed configuration
      CreateIPPPrinterQueues Everywhere
      BrowseRemoteProtocols dnssd
      BrowseProtocols All
    '';
    
    # Configure cupsd.conf settings
    extraConf = ''
      # Log general information in error_log - change "warn" to "debug" for troubleshooting
      LogLevel warn
      PageLogFormat
      
      # Specifies the maximum size of the log files before they are rotated. The value "0" disables log rotation.
      MaxLogSize 0
      
      # Default error policy for printers
      ErrorPolicy retry-job
      
      # Only listen for connections from the local machine.
      Listen localhost:631
      Listen /run/cups/cups.sock
      
      # Show shared printers on the local network.
      Browsing Yes
      BrowseLocalProtocols dnssd
      
      # Default authentication type, when authentication is required
      DefaultAuthType Basic
      
      # Web interface setting
      WebInterface Yes
      
      # Timeout after cupsd exits if idle (applied only if cupsd runs on-demand - with -l)
      IdleExitTimeout 60
      
      # Restrict access to the server
      <Location />
        Order allow,deny
      </Location>
      
      # Restrict access to the admin pages
      <Location /admin>
        Order allow,deny
      </Location>
      
      # Restrict access to configuration files
      <Location /admin/conf>
        AuthType Default
        Require user @SYSTEM
        Order allow,deny
      </Location>
      
      # Restrict access to log files
      <Location /admin/log>
        AuthType Default
        Require user @SYSTEM
        Order allow,deny
      </Location>
      
      # Set the default printer/job policies
      <Policy default>
        # Job/subscription privacy
        JobPrivateAccess default
        JobPrivateValues default
        SubscriptionPrivateAccess default
        SubscriptionPrivateValues default
        
        # Job-related operations must be done by the owner or an administrator
        <Limit Create-Job Print-Job Print-URI Validate-Job>
          Order deny,allow
        </Limit>
        
        <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job Cancel-My-Jobs Close-Job CUPS-Move-Job CUPS-Get-Document>
          Require user @OWNER @SYSTEM
          Order deny,allow
        </Limit>
        
        # All administration operations require an administrator to authenticate
        <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default CUPS-Get-Devices>
          AuthType Default
          Require user @SYSTEM
          Order deny,allow
        </Limit>
        
        # All printer operations require a printer operator to authenticate
        <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Accept-Jobs CUPS-Reject-Jobs>
          AuthType Default
          Require user @SYSTEM
          Order deny,allow
        </Limit>
        
        # Only the owner or an administrator can cancel or authenticate a job
        <Limit Cancel-Job CUPS-Authenticate-Job>
          Require user @OWNER @SYSTEM
          Order deny,allow
        </Limit>
        
        <Limit All>
          Order deny,allow
        </Limit>
      </Policy>
      
      # Set the authenticated printer/job policies
      <Policy authenticated>
        # Job/subscription privacy
        JobPrivateAccess default
        JobPrivateValues default
        SubscriptionPrivateAccess default
        SubscriptionPrivateValues default
        
        # Job-related operations must be done by the owner or an administrator
        <Limit Create-Job Print-Job Print-URI Validate-Job>
          AuthType Default
          Order deny,allow
        </Limit>
        
        <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job Cancel-My-Jobs Close-Job CUPS-Move-Job CUPS-Get-Document>
          AuthType Default
          Require user @OWNER @SYSTEM
          Order deny,allow
        </Limit>
        
        # All administration operations require an administrator to authenticate
        <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default>
          AuthType Default
          Require user @SYSTEM
          Order deny,allow
        </Limit>
        
        # All printer operations require a printer operator to authenticate
        <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Accept-Jobs CUPS-Reject-Jobs>
          AuthType Default
          Require user @SYSTEM
          Order deny,allow
        </Limit>
        
        # Only the owner or an administrator can cancel or authenticate a job
        <Limit Cancel-Job CUPS-Authenticate-Job>
          AuthType Default
          Require user @OWNER @SYSTEM
          Order deny,allow
        </Limit>
        
        <Limit All>
          Order deny,allow
        </Limit>
      </Policy>
      
      # Set the kerberized printer/job policies
      <Policy kerberos>
        # Job/subscription privacy
        JobPrivateAccess default
        JobPrivateValues default
        SubscriptionPrivateAccess default
        SubscriptionPrivateValues default
        
        # Job-related operations must be done by the owner or an administrator
        <Limit Create-Job Print-Job Print-URI Validate-Job>
          AuthType Negotiate
          Order deny,allow
        </Limit>
        
        <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job Cancel-My-Jobs Close-Job CUPS-Move-Job CUPS-Get-Document>
          AuthType Negotiate
          Require user @OWNER @SYSTEM
          Order deny,allow
        </Limit>
        
        # All administration operations require an administrator to authenticate
        <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default>
          AuthType Default
          Require user @SYSTEM
          Order deny,allow
        </Limit>
        
        # All printer operations require a printer operator to authenticate
        <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Accept-Jobs CUPS-Reject-Jobs>
          AuthType Default
          Require user @SYSTEM
          Order deny,allow
        </Limit>
        
        # Only the owner or an administrator can cancel or authenticate a job
        <Limit Cancel-Job CUPS-Authenticate-Job>
          AuthType Negotiate
          Require user @OWNER @SYSTEM
          Order deny,allow
        </Limit>
        
        <Limit All>
          Order deny,allow
        </Limit>
      </Policy>
    '';
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

    # Enable and accept ZebraRaw printer after CUPS starts
    systemd.services.zebra-printer-setup = {
      description = "Enable and accept ZebraRaw printer";
      after = [ "cups.service" ];
      requires = [ "cups.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.cups}/bin/cupsenable ZebraRaw
          ${pkgs.cups}/bin/cupsaccept ZebraRaw
        '';
        User = "root";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 30;
      };
    };

    networking.firewall.enable = true;
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Zurich";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    system.stateVersion = "25.05";
}
