{ config, lib, pkgs, ... }:

let
  cfg = config.services.printer-setup;
  
  printerSetupScript = pkgs.writeScriptBin "setup-usb-printers" ''
    #!${pkgs.bash}/bin/bash
    
    set -e
    
    echo "Auto-detecting and setting up USB printers..."
    
    # Wait for CUPS to be ready
    echo "Waiting for CUPS to be ready..."
    for i in {1..30}; do
      if ${pkgs.cups}/bin/lpstat -r >/dev/null 2>&1; then
        echo "CUPS is ready"
        break
      fi
      sleep 1
    done
    
    # Function to detect USB printers
    detect_usb_printers() {
      echo "Scanning for USB printers..."
      
      # Use lsusb to find USB devices
      if ! command -v lsusb >/dev/null 2>&1; then
        echo "lsusb not available, installing usbutils..."
        ${pkgs.usbutils}/bin/lsusb
      fi
      
      # Look for USB devices (printers typically have vendor/product IDs)
      local usb_devices=$(${pkgs.usbutils}/bin/lsusb || true)
      
      if [ -z "$usb_devices" ]; then
        echo "No USB devices detected via lsusb"
        return 1
      fi
      
      echo "Found USB devices:"
      echo "$usb_devices"
      
      # Use CUPS device discovery for USB printers
      echo "Scanning CUPS USB devices..."
      local cups_devices=$(${pkgs.cups}/bin/lpinfo -v | grep -i "usb://" || true)
      
      if [ -z "$cups_devices" ]; then
        echo "No USB printers detected via CUPS"
        return 1
      fi
      
      echo "Found CUPS USB devices:"
      echo "$cups_devices"
      
      # Process each detected USB device
      echo "$cups_devices" | while read -r device_uri; do
        if [[ "$device_uri" =~ usb:// ]]; then
          setup_printer "$device_uri"
        fi
      done
    }
    
    # Function to detect specific brand printers
    detect_brand_printers() {
      local brand="$1"
      echo "Scanning for $brand printers..."
      
      # Use CUPS device discovery for specific brand
      local cups_devices=$(${pkgs.cups}/bin/lpinfo -v | grep -i "usb://" | grep -i "$brand" || true)
      
      if [ -z "$cups_devices" ]; then
        echo "No $brand printers detected via CUPS"
        return 1
      fi
      
      echo "Found CUPS $brand devices:"
      echo "$cups_devices"
      
      # Process each detected device
      echo "$cups_devices" | while read -r device_uri; do
        if [[ "$device_uri" =~ usb:// ]]; then
          setup_printer "$device_uri"
        fi
      done
    }
    
    # Function to setup a single printer
    setup_printer() {
      local device_uri="$1"
      local printer_name=""
      local driver_model=""
      
      # Extract information from URI for naming and driver selection
      local vendor=""
      local product=""
      local serial=""
      
      # Parse USB URI components
      if [[ "$device_uri" =~ usb://([^/]+)/([^?]+) ]]; then
        vendor="${BASH_REMATCH[1]}"
        product="${BASH_REMATCH[2]}"
      fi
      
      if [[ "$device_uri" =~ serial=([^&]+) ]]; then
        serial="${BASH_REMATCH[1]}"
      fi
      
      # Generate printer name
      if [ -n "$serial" ]; then
        printer_name="${vendor}_${serial}"
      elif [ -n "$vendor" ] && [ -n "$product" ]; then
        printer_name="${vendor}_${product}"
      else
        printer_name="USB_Printer_$(date +%s)"
      fi
      
      # Clean up printer name (replace spaces and special chars)
      printer_name=$(echo "$printer_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
      
      # Determine driver model based on vendor/product
      if [[ "$vendor" =~ [Zz]ebra ]]; then
        driver_model="raw"
      elif [[ "$vendor" =~ [Hh]ewlett.*[Pp]ackard ]] || [[ "$vendor" =~ [Hh][Pp] ]]; then
        driver_model="drv:///sample.drv/generic.ppd"
      elif [[ "$vendor" =~ [Cc]anon ]]; then
        driver_model="drv:///sample.drv/generic.ppd"
      elif [[ "$vendor" =~ [Ee]pson ]]; then
        driver_model="drv:///sample.drv/generic.ppd"
      elif [[ "$vendor" =~ [Bb]rother ]]; then
        driver_model="drv:///sample.drv/generic.ppd"
      else
        driver_model="raw"  # Default to raw for unknown printers
      fi
      
      echo "Setting up printer: $printer_name"
      echo "Device URI: $device_uri"
      echo "Driver: $driver_model"
      
      # Check if printer already exists
      if ${pkgs.cups}/bin/lpstat -p "$printer_name" >/dev/null 2>&1; then
        echo "Printer $printer_name already exists, removing..."
        ${pkgs.cups}/bin/lpadmin -x "$printer_name"
      fi
      
      # Add the printer
      echo "Adding printer $printer_name..."
      ${pkgs.cups}/bin/lpadmin -p "$printer_name" -E -v "$device_uri" -m "$driver_model"
      
      # Enable the printer
      echo "Enabling printer..."
      ${pkgs.cups}/bin/cupsenable "$printer_name"
      ${pkgs.cups}/bin/cupsaccept "$printer_name"
      
      # Set as default printer if specified
      if [ "${cfg.usbPrinters.setAsDefault}" = "true" ]; then
        echo "Setting as default printer..."
        ${pkgs.cups}/bin/lpoptions -d "$printer_name"
      fi
      
      echo "Printer $printer_name setup complete!"
      echo "Printer status:"
      ${pkgs.cups}/bin/lpstat -p "$printer_name"
      echo ""
    }
    
    # Function to setup specific printer if URI is provided
    setup_specific_printer() {
      local printer_name="${cfg.usbPrinters.name}"
      local device_uri="${cfg.usbPrinters.uri}"
      local driver_model="${cfg.usbPrinters.driver}"
      
      echo "Setting up specific printer: $printer_name"
      
      # Check if printer already exists
      if ${pkgs.cups}/bin/lpstat -p "$printer_name" >/dev/null 2>&1; then
        echo "Printer $printer_name already exists, removing..."
        ${pkgs.cups}/bin/lpadmin -x "$printer_name"
      fi
      
      # Add the printer
      echo "Adding printer $printer_name..."
      ${pkgs.cups}/bin/lpadmin -p "$printer_name" -E -v "$device_uri" -m "$driver_model"
      
      # Enable the printer
      echo "Enabling printer..."
      ${pkgs.cups}/bin/cupsenable "$printer_name"
      ${pkgs.cups}/bin/cupsaccept "$printer_name"
      
      # Set as default printer if specified
      if [ "${cfg.usbPrinters.setAsDefault}" = "true" ]; then
        echo "Setting as default printer..."
        ${pkgs.cups}/bin/lpoptions -d "$printer_name"
      fi
      
      echo "Printer $printer_name setup complete!"
      echo "Printer status:"
      ${pkgs.cups}/bin/lpstat -p "$printer_name"
    }
    
    # Main logic
    if [ "${cfg.usbPrinters.autoDetect}" = "true" ]; then
      # Auto-detect mode
      if [ "${cfg.usbPrinters.detectAll}" = "true" ]; then
        # Detect all USB printers
        detect_usb_printers
      else
        # Detect specific brand printers
        for brand in ${cfg.usbPrinters.brands}; do
          detect_brand_printers "$brand"
        done
      fi
    else
      # Specific printer mode
      setup_specific_printer
    fi
    
    echo "All printer setup operations completed!"
  '';

in {
  options.services.printer-setup = {
    enable = lib.mkEnableOption "Automatic printer setup";
    
    usbPrinters = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic USB printer setup";
      };
      
      autoDetect = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Automatically detect USB printers instead of using specific URI";
      };
      
      detectAll = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Detect all USB printers (if false, only detect specific brands)";
      };
      
      brands = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "Zebra" "HP" "Canon" "Epson" "Brother" ];
        description = "List of printer brands to detect (used only if detectAll = false)";
      };
      
      name = lib.mkOption {
        type = lib.types.str;
        default = "USBPrinter";
        description = "Name for the USB printer in CUPS (used only if autoDetect = false)";
      };
      
      uri = lib.mkOption {
        type = lib.types.str;
        default = "usb://Zebra%20Technologies/ZTC%20ZD421-203dpi%20ZPL?serial=D8J234508875";
        description = "USB URI for the printer (used only if autoDetect = false)";
      };
      
      driver = lib.mkOption {
        type = lib.types.str;
        default = "raw";
        description = "Driver model for the printer";
      };
      
      setAsDefault = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Set the first detected printer as the default printer";
      };
    };
    
    # Keep backward compatibility with old zebraPrinter options
    zebraPrinter = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Zebra printer setup (deprecated, use usbPrinters instead)";
          };
          
          autoDetect = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Automatically detect Zebra printers (deprecated)";
          };
          
          name = lib.mkOption {
            type = lib.types.str;
            default = "ZebraRaw";
            description = "Name for the Zebra printer (deprecated)";
          };
          
          uri = lib.mkOption {
            type = lib.types.str;
            default = "usb://Zebra%20Technologies/ZTC%20ZD421-203dpi%20ZPL?serial=D8J234508875";
            description = "USB URI for the Zebra printer (deprecated)";
          };
          
          driver = lib.mkOption {
            type = lib.types.str;
            default = "raw";
            description = "Driver model for the Zebra printer (deprecated)";
          };
          
          setAsDefault = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Set Zebra printer as default (deprecated)";
          };
        };
      };
      default = {};
      description = "Zebra printer configuration (deprecated, use usbPrinters instead)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ printerSetupScript ];
    
    # Add usbutils for device detection
    environment.systemPackages = with pkgs; [ usbutils ];
    
    systemd.services.printer-setup = lib.mkIf cfg.usbPrinters.enable {
      description = "Setup USB printers in CUPS";
      after = [ "cups.service" ];
      requires = [ "cups.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${printerSetupScript}/bin/setup-usb-printers";
        User = "root";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 30;  # Longer restart interval for auto-detection
      };
    };
  };
} 