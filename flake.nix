{
  description = "Solana CLI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    solanaSrc.url = "github:solana-labs/solana?rev=4892eb4e1ad278d5249b6cda8983f88effb3e98b";
    solanaSrc.flake = false;
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, solanaSrc, fenix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ fenix.overlay ];
        };

        # https://github.com/solana-labs/solana/blob/master/scripts/cargo-install-all.sh#L71
        endUserBins = [
          "cargo-build-bpf"
          "cargo-test-bpf"
          "solana"
          "solana-install"
          "solana-install-init"
          "solana-keygen"
          "solana-faucet"
          "solana-stake-accounts"
          "solana-tokens"
          # Linker error on Darwin about System framework
          # "solana-test-validator"
        ];

        meta = with pkgs.stdenv; with pkgs.lib; {
          homepage = "https://solana.com/";
          description = "Solana is a decentralized blockchain built to enable scalable, user-friendly apps for the world.";
          platforms = platforms.unix ++ platforms.darwin;
        };

        # Here's an unfinished attempt at adding solana to Nixpkgs where the
        # person had to remove some tests and comment some out.
        # https://github.com/NixOS/nixpkgs/pull/121009/files
        solana = pkgs.rustPlatform.buildRustPackage
          rec {
            inherit meta;
            pname = "solana";
            version = "1.7.15";
            src = solanaSrc;
            cargoSha256 = "1ndvqskfcix17a5h2rwcnhyq14ngcnaq9kmaq2qvxr8lgv23an21";

            doCheck = false;

            nativeBuildInputs = with pkgs; [
              rustfmt
              llvm
              clang
              protobuf
              pkg-config
            ];

            buildInputs = with pkgs; [
              hidapi
              rustfmt
              libclang
              openssl
              zlib
            ] ++ (with pkgs.darwin.apple_sdk.frameworks; pkgs.lib.optionals pkgs.stdenv.isDarwin [
              System
              IOKit
              Security
              CoreFoundation
              AppKit
            ]) ++ (pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.udev ]);

            # https://hoverbear.org/blog/rust-bindgen-in-nix/
            preBuild = with pkgs; ''
              # From: https://github.com/NixOS/nixpkgs/blob/1fab95f5190d087e66a3502481e34e15d62090aa/pkgs/applications/networking/browsers/firefox/common.nix#L247-L253
              # Set C flags for Rust's bindgen program. Unlike ordinary C
              # compilation, bindgen does not invoke $CC directly. Instead it
              # uses LLVM's libclang. To make sure all necessary flags are
              # included we need to look in a few places.
              export BINDGEN_EXTRA_CLANG_ARGS="$(< ${stdenv.cc}/nix-support/libc-crt1-cflags) \
                $(< ${stdenv.cc}/nix-support/libc-cflags) \
                $(< ${stdenv.cc}/nix-support/cc-cflags) \
                $(< ${stdenv.cc}/nix-support/libcxx-cxxflags) \
                ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
                ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"} \
              "
            '';

            postInstall = ''
              cp -r ${solanaSrc}/sdk $out/bin/sdk
            '';

            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            LLVM_CONFIG_PATH = "${pkgs.llvm}/bin/llvm-config";

            cargoBuildFlags = builtins.map (binName: "--bin=${binName}") endUserBins;
          };

      in
      rec {
        packages = flake-utils.lib.flattenTree {
          inherit solana;
        };
        defaultPackage = packages.solana;
        apps.solana = flake-utils.lib.mkApp { drv = packages.solana; };
        defaultApp = apps.solana;
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            (fenix.packages.x86_64-darwin.complete.withComponents [
              "cargo"
              "clippy"
              "rust-src"
              "rustc"
              "rustfmt"
            ])
          ];
        };
      }
    );
}
