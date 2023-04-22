{
  description = "A multi-physics finite element solver designed for computational modeling of the cardiovascular system";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-compat.flake = false;
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    { self
    , nixpkgs
    , flake-compat
    , flake-utils
    ,
    } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        mkl-aarch = pkgs.mkl.overrideAttrs (final: prev: {
          meta.platforms = prev.meta.platforms ++ [ "aarch64-darwin" ];
        });

        svfsi = pkgs.stdenv.mkDerivation {
          name = "svfsi-src";
          version = "latest";
          src = ./.;
          buildInputs = [
            pkgs.boost166
            pkgs.cmake
            pkgs.hdf5
            pkgs.lapack
            # pkgs.mkl
            pkgs.darwin.DarwinTools
            mkl-aarch
            pkgs.mpi
            pkgs.mpich
            pkgs.trilinos
          ]
          ++ (
            if pkgs.stdenv.isDarwin
            then [ pkgs.darwin.DarwinTools ]
            else [ ]
          );
          configurePhase = ''
            export FC=${pkgs.mpi}/bin/mpif77
            cmake .
          '';
          buildPhase = ''
            make
          '';
          installPhase = ''
            mkdir -p $out
            ls -FhoA
            cp -r ./svFSI-build/* $out/
          '';
        };

        svfsi-app = pkgs.writeShellApplication {
          name = "svfsi";
          text = ''
            ${svfsi}/bin/svFSI "$@"
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.alejandra
            svfsi-app
          ];
        };

        packages = {
          inherit svfsi svfsi-app;
        };
      }
    );
}
