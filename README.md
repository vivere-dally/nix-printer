# Aiconomy AG NixOS for RaspberryPi Print Nodes 

## Build

```sh
nix-build -E 'with import <nixpkgs> { }; callPackage ./print-node.nix { tar = gnutar; }' 
```

```sh
nix build --extra-experimental-features "nix-command flakes" ./nixos/flake.nix#packages.aarch64-linux.sdcard
```
