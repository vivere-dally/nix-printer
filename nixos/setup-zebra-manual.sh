#!/bin/bash

# Manual USB printer setup script with auto-detection
# Run this script to immediately set up any detected USB printer in CUPS

set -e

echo "Auto-detecting and setting up USB printers..."

# Check if CUPS is running
if ! lpstat -r >/dev/null 2>&1; then
    echo "Error: CUPS is not running. Please start CUPS first:"
    echo "  sudo systemctl start cups"
    exit 1
fi

# Function to detect all USB printers
detect_usb_printers() {
    echo "Scanning for USB printers..."
    
    # Use lsusb to find USB devices
    if ! command -v lsusb >/dev/null 2>&1; then
        echo "lsusb not available. Please install usbutils:"
        echo "  sudo apt-get install usbutils"
        exit 1
    fi
    
    # Look for USB devices
    local usb_devices=$(lsusb || true)
    
    if [ -z "$usb_devices" ]; then
        echo "No USB devices detected via lsusb"
        echo "Make sure USB devices are connected"
        return 1
    fi
    
    echo "Found USB devices:"
    echo "$usb_devices"
    
    # Use CUPS device discovery for USB printers
    echo "Scanning CUPS USB devices..."
    local cups_devices=$(lpinfo -v | grep -i "usb://" || true)
    
    if [ -z "$cups_devices" ]; then
        echo "No USB printers detected via CUPS"
        echo "Try running: sudo systemctl restart cups"
        return 1
    fi
    
    echo "Found CUPS USB devices:"
    echo "$cups_devices"
    
    # Process each detected USB device
    local printer_count=0
    echo "$cups_devices" | while read -r device_uri; do
        if [[ "$device_uri" =~ usb:// ]]; then
            setup_printer "$device_uri"
            printer_count=$((printer_count + 1))
        fi
    done
    
    if [ $printer_count -eq 0 ]; then
        echo "No USB printers were successfully configured"
        return 1
    fi
}

# Function to detect specific brand printers
detect_brand_printers() {
    local brand="$1"
    echo "Scanning for $brand printers..."
    
    # Use CUPS device discovery for specific brand
    local cups_devices=$(lpinfo -v | grep -i "usb://" | grep -i "$brand" || true)
    
    if [ -z "$cups_devices" ]; then
        echo "No $brand printers detected via CUPS"
        return 1
    fi
    
    echo "Found CUPS $brand devices:"
    echo "$cups_devices"
    
    # Process each detected device
    local printer_count=0
    echo "$cups_devices" | while read -r device_uri; do
        if [[ "$device_uri" =~ usb:// ]]; then
            setup_printer "$device_uri"
            printer_count=$((printer_count + 1))
        fi
    done
    
    if [ $printer_count -eq 0 ]; then
        echo "No $brand printers were successfully configured"
        return 1
    fi
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
    if lpstat -p "$printer_name" >/dev/null 2>&1; then
        echo "Printer $printer_name already exists, removing..."
        sudo lpadmin -x "$printer_name"
    fi
    
    # Add the printer
    echo "Adding printer $printer_name..."
    sudo lpadmin -p "$printer_name" -E -v "$device_uri" -m "$driver_model"
    
    # Enable the printer
    echo "Enabling printer..."
    sudo cupsenable "$printer_name"
    sudo cupsaccept "$printer_name"
    
    # Set as default printer if this is the first one
    if [ "$SET_AS_DEFAULT" = "true" ]; then
        echo "Setting as default printer..."
        lpoptions -d "$printer_name"
    fi
    
    echo "Printer $printer_name setup complete!"
    echo "Printer status:"
    lpstat -p "$printer_name"
    echo ""
}

# Function to setup specific printer
setup_specific_printer() {
    local printer_name="${1:-USBPrinter}"
    local device_uri="${2:-usb://Zebra%20Technologies/ZTC%20ZD421-203dpi%20ZPL?serial=D8J234508875}"
    local driver_model="${3:-raw}"
    
    echo "Setting up specific printer: $printer_name"
    
    # Check if printer already exists
    if lpstat -p "$printer_name" >/dev/null 2>&1; then
        echo "Printer $printer_name already exists, removing..."
        sudo lpadmin -x "$printer_name"
    fi
    
    # Add the printer
    echo "Adding printer $printer_name..."
    sudo lpadmin -p "$printer_name" -E -v "$device_uri" -m "$driver_model"
    
    # Enable the printer
    echo "Enabling printer..."
    sudo cupsenable "$printer_name"
    sudo cupsaccept "$printer_name"
    
    # Set as default printer
    echo "Setting as default printer..."
    lpoptions -d "$printer_name"
    
    echo "Printer $printer_name setup complete!"
    echo "Printer status:"
    lpstat -p "$printer_name"
}

# Parse command line arguments
AUTO_DETECT=true
SET_AS_DEFAULT=true
DETECT_ALL=true
BRAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --specific)
            AUTO_DETECT=false
            shift
            ;;
        --brand)
            DETECT_ALL=false
            BRAND="$2"
            shift 2
            ;;
        --no-default)
            SET_AS_DEFAULT=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --specific         Use specific printer URI instead of auto-detection"
            echo "  --brand BRAND      Detect only specific brand (e.g., Zebra, HP, Canon)"
            echo "  --no-default       Don't set the printer as default"
            echo "  --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Auto-detect and setup ALL USB printers"
            echo "  $0 --brand Zebra      # Setup only Zebra printers"
            echo "  $0 --brand HP         # Setup only HP printers"
            echo "  $0 --specific         # Setup specific printer with default URI"
            echo "  $0 --no-default       # Auto-detect but don't set as default"
            echo ""
            echo "Supported brands: Zebra, HP, Canon, Epson, Brother"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main logic
if [ "$AUTO_DETECT" = true ]; then
    if [ "$DETECT_ALL" = true ]; then
        # Auto-detect all USB printers
        detect_usb_printers
    else
        # Auto-detect specific brand
        if [ -n "$BRAND" ]; then
            detect_brand_printers "$BRAND"
        else
            echo "Error: --brand option requires a brand name"
            exit 1
        fi
    fi
else
    # Specific printer mode
    setup_specific_printer
fi

echo "All printer setup operations completed!"
echo ""
echo "To test the printer(s), you can run:"
echo "  lpstat -p                    # List all printers"
echo "  echo 'Test print' | lpr      # Print to default printer"
echo "  echo 'Test print' | lpr -P PRINTER_NAME  # Print to specific printer" 