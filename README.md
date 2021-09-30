# Nix Flake For Solana

This flake packages up the [solana-cli](https://docs.solana.com/cli/install-solana-cli-tools), or at least it tries to. It includes two outputs, `solana` and `solana-bin`.

The first builds all CLI tools from source. I tested this on my NixOS machine, where the build succeeds and I can run `$ ./result/bin/solana --version`. The build fails on my M1 Darwin machine though, because I don't know how to make the linker aware of the `System` MacOS framework. More details can be found [in my Discourse question](https://discourse.nixos.org/t/ld-framework-not-found-system/15096).

The second output is an already built binary. This was tested on both MacOS and NixOS. On NixOS there are two dynamically linked libraries I couldn't locate, but I don't know for which CLI commands these are relevant.

Summary: I can't guarantee that all CLI commands work. Your best bet is using
`solana-bin` on Darwin and `solana` on NixOS.

