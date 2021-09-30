# Nix Flake For Solana

This flake packages up the [solana-cli](https://docs.solana.com/cli/install-solana-cli-tools), or at least it tries to. It includes two outputs, `solana` and `solana-bin`.

The first builds all CLI tools from source. I tested this on my NixOS machine, where the build succeeds and I can run `$ ./result/bin/solana --version`. The build fails on my M1 Darwin machine though, because I don't know how to make the linker aware of the `System` MacOS framework. More details can be found [in my Discourse question](https://discourse.nixos.org/t/ld-framework-not-found-system/15096).

The second output is an already built binary. This was tested on both MacOS and NixOS. On NixOS there are two dynamically linked libraries I couldn't locate, but I don't know for which CLI commands these are relevant.

Summary: I can't guarantee that all CLI commands work. Your best bet is using
`solana-bin` on Darwin and `solana` on NixOS.

## Quickstart

```shell
$ nix flake show github:cideM/solana-nix
github:cideM/solana-nix/0eea6618318be7744e9e9f4cab64bcf92371fa3e
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
│   ├───aarch64-darwin: package 'solana-1.8.0'
│   ├───x86_64-darwin: package 'solana-1.8.0'
│   └───x86_64-linux: package 'solana-1.8.0'
└───packages
    ├───aarch64-darwin
    │   ├───solana: package 'solana-1.8.0'
    │   └───solana-bin: package 'solana-cli-bin'
    ├───x86_64-darwin
    │   ├───solana: package 'solana-1.8.0'
    │   └───solana-bin: package 'solana-cli-bin'
    └───x86_64-linux
        ├───solana: package 'solana-1.8.0'
        └───solana-bin: package 'solana-cli-bin'
$ nix build github:cideM/solana-nix#solana-bin
$ ./result/bin/solana --version
solana-cli 1.6.27 (src:c5d174c1; feat:1203293006)
```
