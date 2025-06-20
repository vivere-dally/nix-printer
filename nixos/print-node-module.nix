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
                extraGroups = [ "wheel" "lp" "scanner" "lpadmin" ]; # CUPS permissions
            };
        };

        users.groups = lib.optionalAttrs (cfg.group == "aico-printnode") {
            aico-printnode = {};
        };

        systemd.services.print-node = {
            description = "PrintNode Client";
            after = [ "network.target" "cups.service" ];
            requires = [ "cups.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
                ExecStart = "${cfg.package}/bin/PrintNode";
                User = cfg.user;
                Group = cfg.group;
                Restart = "always";
                RestartSec = 5;
                StandardOutput = "journal";
                StandardError = "journal";
            };
        };
    };
}
