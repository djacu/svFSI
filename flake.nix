{
  description = "A multi-physics finite element solver designed for computational modeling of the cardiovascular system";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-compat.flake = false;
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.svfsi-src.url = "github:djacu/svFSI";
  inputs.svfsi-src.flake = false;

  outputs = {
    self,
    nixpkgs,
    flake-compat,
    flake-utils,
    svfsi-src,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        svfsi = pkgs.stdenv.mkDerivation {
          name = "svfsi-src";
          version = "latest";
          src = svfsi-src;
          buildInputs = [
            pkgs.boost166
            pkgs.cmake
            pkgs.cmakeCurses
            pkgs.hdf5
            pkgs.lapack
            pkgs.mkl
            pkgs.mpi
            pkgs.mpich
            pkgs.ncurses5
            pkgs.trilinos
          ];
          configurePhase = ''
            ls -FhoA
            export CMAKE_Fortran_COMPILER=${pkgs.mpi}/bin/mpif77
            export FC=${pkgs.mpi}/bin/mpif77
            echo $CMAKE_Fortran_COMPILER
            echo $FC
            cmake .
          '';
          buildPhase = ''
            make
          '';
          installPhase = ''
            mkdir -p $out/build
            cp -r * $out/build/
          '';
          NIXPKGS_ALLOW_UNFREE = 1;
          shellHook = ''
            export CMAKE_Fortran_COMPILER=${pkgs.mpi}/bin/mpif77
          '';
        };

      in {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.alejandra
          ];
        };

        packages = {
          inherit svfsi;
        };
      }
    );
}
