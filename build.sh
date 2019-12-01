#!/bin/sh
exec nix-build -E \
  'with import <nixpkgs> { overlays = [ (import ./.) ]; }; vscode-extensions.matklad.ra-lsp' \
  "$@"

