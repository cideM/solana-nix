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

        # https://github.com/solana-labs/solana/blob/master/scripts/cargo-install-all.sh#L71
        endUserBins = [
          "cargo-build-bpf"
          "cargo-test-bpf"
          "solana"
          "solana-install"
          "solana-install-init"
          "solana-keygen"
          "solana-stake-accounts"
          "solana-test-validator"
          "solana-tokens"
        ];

        meta = with pkgs.stdenv; with pkgs.lib; {
          homepage = "https://solana.com/";
          description = "Solana is a decentralized blockchain built to enable scalable, user-friendly apps for the world.";
          platforms = platforms.unix ++ platforms.darwin;
        };

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
        solanaFromSource = pkgs.rustPlatform.buildRustPackage
          rec {
            inherit meta;
            pname = "solana";
            version = "1.8.0";
            src = solanaSrc;
            cargoSha256 = "0yahdh6pzi6xsikz7z6k72hpqv9fkph2ns3m4v99hm5j61q86nfk";

            doCheck = false;

            # I commented the dependencies out one by one and checked if the
            # build fails. The below is the result of that testing.
            nativeBuildInputs = [
              pkgs.rustfmt
              pkgs.llvm
              pkgs.clang
              pkgs.protobuf
              pkgs.pkg-config
            ];

            buildInputs = [
              pkgs.hidapi
              pkgs.llvmPackages.libclang
              pkgs.rustfmt
              pkgs.openssl
              pkgs.zlib
            ] ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.System
            ]) ++ (pkgs.lib.optionals pkgs.stdenv.isLinux pkgs.udev);

            # This is how you should do it for Rust bindgen, instead of the
            # NIX_LDFLAGS
            BINDGEN_EXTRA_CLANG_ARGS = "-isystem";
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            LLVM_CONFIG_PATH = "${pkgs.llvm}/bin/llvm-config";

            cargoBuildFlags = builtins.map (binName: "--bin=${binName}") endUserBins;
          };

      in
      rec {
        packages = flake-utils.lib.flattenTree {
          solana = solanaFromSource;
        };
        defaultPackage = packages.solana;
        apps.solana = flake-utils.lib.mkApp { drv = packages.solana; };
        defaultApp = apps.solana;
      }
    );
}
