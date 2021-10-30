#!/usr/bin/env fish

set -l url "https://github.com/solana-labs/bpf-tools/releases/download/v1.12/"

set -l macos_file "solana-bpf-tools-osx.tar.bz2"
set -l linux_file "solana-bpf-tools-linux.tar.bz2"

echo "macos: " (nix-hash --type sha256 --base32 --flat (curl -LsSo - $url$macos_file | psub))
echo "linux: " (nix-hash --type sha256 --base32 --flat (curl -LsSo - $url$linux_file | psub))
