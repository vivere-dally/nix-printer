# default.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.callPackage ./print-node.nix {}

