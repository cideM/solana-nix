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
        solanaSrc = pkgs.rustPlatform.buildRustPackage rec {
          pname = "solana";
          version = "latest";
          src = solanaSrc;
          cargoSha256 = "034hdyziagvg63q2lr226qw3myy5458rb82277vkxp1xsbamh70l";

          nativeBuildInputs = [
            pkgs.hidapi
            pkgs.llvmPackages.clang
            pkgs.llvm
            pkgs.rustfmt
            # pkgs.darwin.apple_sdk.frameworks.System
            pkgs.llvmPackages.libclang
            pkgs.pkg-config
          ];

          buildInputs = [
            pkgs.hidapi
            pkgs.llvm
            pkgs.llvmPackages.libclang
            pkgs.rustfmt
            # pkgs.darwin.apple_sdk.frameworks.System
            pkgs.openssl
            # pkgs.udev
            pkgs.zlib
          ];

          preBuild = ''
            export LLVM_CONFIG_PATH="${pkgs.llvm}/bin/llvm-config";
            export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib";
          '';

          # preConfigure = ''
          #   export NIX_LDFLAGS="-F${pkgs.darwin.apple_sdk.frameworks.System}/Library/Frameworks -framework System $NIX_LDFLAGS";
          # '';
        };

        solanaBin = pkgs.stdenv.mkDerivation {
          name = "solana-cli";

          src = pkgs.fetchurl {
            url = "https://github.com/solana-labs/solana/releases/download/v1.6.25/solana-release-x86_64-apple-darwin.tar.bz2";
            sha256 = "1n0k0y5ix4y9lxbzllzgi8ax992sksxfbgi8x7inqbpavqhj1jpg";
          };

          installPhase = ''
            runHook postInstall

            mkdir $out

            cp -R ./* $out/

            runHook postInstall
          '';
        };

      in
      rec {
        packages = flake-utils.lib.flattenTree {
          solana = if pkgs.stdenv.isDarwin then solanaBin else solanaSrc;
        };
        defaultPackage = packages.solana;
        apps.solana = flake-utils.lib.mkApp { drv = packages.solana; };
        defaultApp = apps.solana;
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.cargo
            pkgs.rustc
            pkgs.nodejs-slim
            pkgs.nodePackages.yarn
            packages.solana
          ];
        };
      }
    );
}

