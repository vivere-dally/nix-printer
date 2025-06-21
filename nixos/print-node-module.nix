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

        systemd.services.print-node = {
            description = "PrintNode Client";
            after = [ "network.target" "cups.service" ];
            requires = [ "cups.service" ];
            wants = [ "cups.socket" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
                ExecStart = "${cfg.package}/bin/PrintNode";
                User = "root";
                Group = "root";
                Restart = "always";
                RestartSec = 5;
                StandardOutput = "journal";
                StandardError = "journal";
            };
        };

        systemd.services.aico-usbprinters = {
            description = "Automatic USB printer detection and configuration";
            after = [ "network.target" "cups.service" "print-node.service" ];
            requires = [ "cups.service" "print-node.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
                Type = "oneshot";
                User = "root";
                Group = "root";
                StandardOutput = "journal";
                StandardError = "journal";
                RemainAfterExit = true;
                ExecStart = "${pkgs.writeShellScript "aico-usbprinters.sh" ''
#!/bin/bash
exec 1>&2
lpinfo -v | grep usb:// | while read uri; do
    read -r -a parts <<< "\$uri"
    printerUri="\$parts[1]"
    echo "Found USB printer: \$printerUri"
                
    name="\$(echo \"\$printerUri\" | sed 's|usb://||' | tr -d '/' | tr '_' '-')"
    if ! lpstat -p "\$name"; then
        echo "Adding printer: \$name"
        if lpadmin -p "\$name" -E -v "\$printerUri" -m raw; then
            cupsenable "\$name" || echo "Failed to enable \$name"
            cupsaccept "\$name" || echo "Failed to accept jobs for \$name"
            echo "Successfully added printer: \$name"
        else
            echo "Failed to add printer: \$name"
        fi
    else
        echo "Printer \$name already exists"
    fi
done
''}";
            };
        };
    };
}
