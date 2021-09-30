{
  description = "Solana CLI";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.solanaSrc.url = "github:solana-labs/solana";
  inputs.solanaSrc.flake = false;

  outputs = { self, nixpkgs, flake-utils, solanaSrc }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # I don't know how to build from source on Darwin
        # https://discourse.nixos.org/t/ld-framework-not-found-system/15096
        # On NixOS the build got to the test stage but then failed at:
        #
        # last 10 log lines:
        # > thread 'test::test_accounts_cluster_bench' panicked at 'Failed to open ledger database: UnableToSetOpenFileDescriptorLimit', core/src/validator.rs:1144:6
        # > note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
        # >
        # >
        # > failures:
        # >     test::test_accounts_cluster_bench
        # >
        # > test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.52s
        # >
        # > error: test failed, to rerun pass '-p solana-accounts-cluster-bench --bin solana-accounts-cluster-bench'
        # For full logs, run 'nix log /nix/store/zpsgi4fw0bhclf2hps1vvhfbv5c71zzp-solana-latest.drv'.
        #
        # Here's an unfinished attempt at adding solana to Nixpkgs where the
        # person had to remove some tests and comment some out.
        # https://github.com/NixOS/nixpkgs/pull/121009/files
        solanaFromSource = pkgs.rustPlatform.buildRustPackage rec {
          pname = "solana";
          version = "1.8.0";
          src = solanaSrc;
          cargoSha256 = "034hdyziagvg63q2lr226qw3myy5458rb82277vkxp1xsbamh70l";

          doCheck = false;

          # I commented the dependencies out one by one and checked if the
          # build fails. The below is the result of that testing.
          nativeBuildInputs = [
            pkgs.rustfmt
            pkgs.llvmPackages.clang # rocksdb
            pkgs.protobuf
            pkgs.llvmPackages.libclang # rocksdb
            pkgs.pkg-config
          ];

          buildInputs = [
            pkgs.hidapi
            pkgs.llvm
            pkgs.llvmPackages.libclang
            pkgs.rustfmt
            pkgs.openssl
            pkgs.udev
            pkgs.zlib
          ];

          preBuild = ''
            export LLVM_CONFIG_PATH="${pkgs.llvm}/bin/llvm-config";
            export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib";
          '';
        };

        solanaBin =
          let sources = {
            "x86_64-darwin" = pkgs.fetchurl {
              url = "https://github.com/solana-labs/solana/releases/download/v1.6.27/solana-release-x86_64-apple-darwin.tar.bz2";
              sha256 = "1n0k0y5ix4y9lxbzllzgi8ax992sksxfbgi8x7inqbpavqhj1jpg";
            };
            "aarch64-darwin" = pkgs.fetchurl {
              url = "https://github.com/solana-labs/solana/releases/download/v1.6.27/solana-release-x86_64-apple-darwin.tar.bz2";
              sha256 = "1n0k0y5ix4y9lxbzllzgi8ax992sksxfbgi8x7inqbpavqhj1jpg";
            };
            "x86_64-linux" = pkgs.fetchurl {
              url = "https://github.com/solana-labs/solana/releases/download/v1.6.27/solana-release-x86_64-unknown-linux-gnu.tar.bz2";
              sha256 = "sha256-iBGrDLVCAQJ9NSwMHz2PiSqeMXghPe+q7Zv3BSTlCro=";
            };
          };
          in
          with pkgs.stdenv; with pkgs.lib; pkgs.stdenv.mkDerivation {
            name = "solana-cli-bin";

            version = "1.6.27";

            src = sources.${system};

            installPhase = ''
              runHook postInstall

              mkdir $out

              cp -R ./* $out/

              runHook postInstall
            '';

            nativeBuildInputs = optional (! isDarwin) pkgs.autoPatchelfHook;

            autoPatchelfIgnoreMissingDeps = true;

            # These are missing but I don't think they're in Nixpkgs
            # > autoPatchelfHook could not satisfy dependency libsgx_uae_service.so wanted by /nix/store/wf6qjpsd7d3fw0cqnxisy82a31lfv404-solana-cli-bin/bin/perf-libs/libsigning.so
            # > autoPatchelfHook could not satisfy dependency libsgx_urts.so wanted by /nix/store/wf6qjpsd7d3fw0cqnxisy82a31lfv404-solana-cli-bin/bin/perf-libs/libsigning.so
            buildInputs = with pkgs; optionals (! isDarwin) [
              openssl
              stdenv.cc.cc.lib
              opencl-icd
              udev
              pkg-config
            ];

            meta = {
              homepage = "https://solana.com/";
              description = "Solana is a decentralized blockchain built to enable scalable, user-friendly apps for the world.";
              platforms = platforms.unix ++ platforms.darwin;
            };
          };

      in
      rec {
        packages = flake-utils.lib.flattenTree {
          solana-bin = solanaBin;
          solana = solanaFromSource;
        };
        defaultPackage = packages.solana;
        apps.solana = flake-utils.lib.mkApp { drv = packages.solana; };
        defaultApp = apps.solana;
      }
    );
}
