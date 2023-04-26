{
  description = "A multi-physics finite element solver designed for computational modeling of the cardiovascular system";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-compat.url = "github:edolstra/flake-compat";
  inputs.flake-compat.flake = false;
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-filter.url = "github:numtide/nix-filter";

  outputs =
    { self
    , nixpkgs
    , flake-compat
    , flake-utils
    , nix-filter
    } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        svfsi = pkgs.stdenv.mkDerivation {
          pname = "svfsi";
          version = "latest";
          src = nix-filter.lib {
            root = ./.;
            include = [
              "Code"
              "Externals"
              "CMakeLists.txt"
            ];
          };
          buildInputs =
            [
              pkgs.blas
              pkgs.boost166
              pkgs.cmake
              pkgs.hdf5
              pkgs.lapack
              pkgs.mpi
              pkgs.mpich
              pkgs.ninja
            ]
            ++ (
              if pkgs.stdenv.isLinux
              then [ pkgs.mkl ]
              else [ ]
            )
            ++ (
              if pkgs.stdenv.isDarwin
              then [ pkgs.darwin.DarwinTools ]
              else [ ]
            );
          preConfigure = ''
            export FC="${pkgs.mpi}/bin/mpif77"
          '';
          installPhase = ''
            mkdir -p $out
            cp -r ./svFSI-build/* $out/
            ln -s svFSI $out/bin/svfsi
          '';
        };
      in
      {
        devShells = {
          default = pkgs.mkShell {
            packages = [
              svfsi
            ];
          };
          dev = pkgs.mkShell {
            packages = [
              pkgs.alejandra
              svfsi
            ];
          };
        };

        packages = {
          inherit svfsi;
        };
      }
    );
}
