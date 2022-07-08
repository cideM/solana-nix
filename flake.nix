{
  description = "Solana CLI";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.solanaSrc.url = "github:solana-labs/solana?rev=e02542003d2c7290704ce155b0dee1d176a6ab27";
  inputs.solanaSrc.flake = false;

  outputs = { self, nixpkgs, flake-utils, solanaSrc }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # https://github.com/solana-labs/solana/blob/master/scripts/cargo-install-all.sh#L71
        endUserBins = [
          "cargo-build-bpf"
          "cargo-test-bpf"
          "solana"
          "solana-install"
          # This doesn't really make much sense with Nix, since it's the job of
          # Nix and this flake to download the necessary dependencies and build
          # the CLI commands.
          # "solana-install-init"
          "solana-keygen"
          "solana-faucet"
          "solana-stake-accounts"
          "solana-tokens"
          # Linker error on Darwin about System framework
          "solana-test-validator"
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
            version = "1.9.15";
            src = solanaSrc;
            cargoSha256 = "1agclib7n2nsaq836vmwdzw0vsb03c1xcsih18nbsjx1jmi8yhn6";

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
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            LLVM_CONFIG_PATH = "${pkgs.llvm}/bin/llvm-config";
            NIX_LDFLAGS="-F${pkgs.darwin.apple_sdk.frameworks.System}/Library/Frameworks -framework System $NIX_LDFLAGS";

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
      }
    );
}
