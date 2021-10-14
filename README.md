# Nix Flake For Solana

This flake packages up the [solana-cli](https://docs.solana.com/cli/install-solana-cli-tools). More specifically, it includes the following binaries:

- cargo-build-bpf
- cargo-test-bpf
- solana
- solana-install
- solana-install-init
- solana-keygen
- solana-faucet
- solana-stake-accounts
- solana-tokens

I tested the build on NixOS and an M1 Darwin machine.

## Quickstart

```shell
$ nix flake show github:cideM/solana-nix
warning: Git tree '/Users/fbs/private/solana-nix' is dirty
git+file:///Users/fbs/private/solana-nix
├───apps
│   ├───aarch64-darwin
│   │   └───solana: app
│   ├───x86_64-darwin
│   │   └───solana: app
│   └───x86_64-linux
│       └───solana: app
├───defaultApp
│   ├───aarch64-darwin: app
│   ├───x86_64-darwin: app
│   └───x86_64-linux: app
├───defaultPackage
│   ├───aarch64-darwin: package 'solana-1.7.15'
│   ├───x86_64-darwin: package 'solana-1.7.15'
│   └───x86_64-linux: package 'solana-1.7.15'
└───packages
    ├───aarch64-darwin
    │   └───solana: package 'solana-1.7.15'
    ├───x86_64-darwin
    │   └───solana: package 'solana-1.7.15'
    └───x86_64-linux
        └───solana: package 'solana-1.7.15'
```
