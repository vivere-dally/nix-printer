# Aiconomy AG NixOS for RaspberryPi Print Nodes 

## Build

```sh
nix-build -E 'with import <nixpkgs> { }; callPackage ./print-node.nix { tar = gnutar; }' 
```

```sh
nix build --extra-experimental-features "nix-command flakes" ./nixos/flake.nix#packages.aarch64-linux.sdcard
```

```sh
cd result/sd-image
sudo unzstd ./nixos-image-sd-card-25.05.20250615.6c64dab-aarch64-linux.img.zst -o nixos-sd-image.img
```
