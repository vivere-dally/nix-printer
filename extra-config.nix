{ config, lib, pkgs, ... }:
{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "aarch64-linux";

  networking.firewall.enable = false;

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
        pkgs.openssh
  ];

  services.openssh.enable = true;
}
