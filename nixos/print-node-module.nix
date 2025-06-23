{ config, lib, pkgs, ... }:
let
    cfg = config.services.print-node;
in {
    options.services.print-node = {
        enable = lib.mkEnableOption "PrintNode service";
        package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.print-node;
            description = "PrintNode package";
        };

        user = lib.mkOption {
            type = lib.types.str;
            default = "aico-printnode";
            description = "User to run PrintNode service";
        };

        group = lib.mkOption {
            type = lib.types.str;
            default = "aico-printnode";
            description = "Group for PrintNode service";
        };

        config = lib.mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = "Configuration file content";
        };
    };

    config = lib.mkIf cfg.enable {
        environment.etc."PrintNode/config.conf" = lib.mkIf (cfg.config != null) {
          text = cfg.config;
          mode = "0644";
        };

        # Dedicated user and group
        users.users = lib.optionalAttrs (cfg.user == "aico-printnode") {
            aico-printnode = {
                isSystemUser = true;
                group = cfg.group;
                extraGroups = [ "wheel" "lp" "lpadmin" "scanner" ]; # CUPS permissions
                createHome = true;
                home = "/home/aico-printnode";
            };
        };

        users.groups = lib.optionalAttrs (cfg.group == "aico-printnode") {
            aico-printnode = {};
        };

        systemd.services.aico-fixbin = {
            description = "Add required binaries to /usr/bin since PrintNode searches for them only there";
            after = [ "network.target" "cups.service" "cups.socket" ];
            wantedBy = [ "multi-user.target" ];
            path = [ pkgs.cups ];
            serviceConfig = {
                Type = "oneshot";
                User = "root";
                StandardOutput = "journal";
                StandardError = "journal";
                RemainAfterExit = true;
                ConditionPathExists = "!/usr/bin/lp";
                ExecStart = let
                    script = pkgs.writeShellScript "aico-fixbin.sh" ''
export PATH=${pkgs.cups}/bin:$PATH
mkdir -p /usr/bin
cd /usr/bin

ln -s /run/current-system/sw/bin/lp
ln -s /run/current-system/sw/bin/lpoptions
ln -s /run/current-system/sw/bin/lpstat
ln -s /run/current-system/sw/bin/ipptool
ln -s /run/current-system/sw/bin/lpr
       '';
    in "${script}";
            };
        };

        systemd.services.print-node = {
            description = "PrintNode Client";
            after = [ "network.target" "cups.service" "cups.socket" "aico-fixbin.service" ];
            requires = [ "cups.service" "cups.socket" ];
            wants = [ "cups.socket" ];
            wantedBy = [ "multi-user.target" ];
            path = [ pkgs.cups cfg.package ];
            serviceConfig = {
                ExecStart = "${cfg.package}/bin/PrintNode";
                User = "root";
                Restart = "always";
                RestartSec = 5;
                StandardOutput = "journal";
                StandardError = "journal";
            };
        };

        systemd.services.aico-printers = {
            description = "Automatic printer detection and configuration";
            after = [ "network.target" "cups.service" "print-node.service" "aico-fixbin.service" ];
            requires = [ "cups.service" "print-node.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
                Type = "oneshot";
                User = "root";
                StandardOutput = "journal";
                StandardError = "journal";
                ExecStart = let
                    script = pkgs.writeShellScript "aico-printers.sh" ''
export PATH=${pkgs.cups}/bin:$PATH
 
lpinfo -v | grep "usb://\|dnssd://" | while read -r line; do
    read -r -a parts <<< "$line"
    printerUri="''${parts[1]}"
    echo "Found printer: $printerUri"

    name=$(echo "$printerUri" | sed \
        -e 's|^usb://||' \
        -e 's|^dnssd://||' \
        -e 's|?.*$||' \
        -e 's|%20|_|g' \
        -e 's|/|_|g' \
        -e 's|[^[:alnum:]_-]|_|g')
    echo "Generated printer name: $name"

    if ! lpstat -p "$name" &>/dev/null; then
        echo "Adding printer: $name"
        if lpadmin -p "$name" -E -v "$printerUri" -m raw; then
            cupsenable "$name"
            cupsaccept "$name"
            echo "Successfully added printer: $name"
        else
            echo "Failed to add printer: $name"
        fi
    else
        echo "Printer $name already exists"
    fi
done
        '';
    in "${script}";
            };
        };

        systemd.timers.aico-printers = {
            wantedBy = ["multi-user.target"];
            timerConfig = {
                OnBootSec = "1min"; # Run 1 minute after boot
                OnUnitActiveSec = "2min"; # Repeat every 2 minutes
                Unit = "aico-printers.service";
            };
        };
    };
}
