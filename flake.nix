{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    crane = {
      url = "github:ipetkov/crane";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          inputs',
          lib,
          pkgs,
          ...
        }:
        let
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain inputs'.rust-overlay.packages.rust;
        in
        {
          devShells.default = craneLib.devShell {
            packages = [
              pkgs.libevent
              pkgs.ncurses
            ];
          };

          packages.default = craneLib.buildPackage {
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                (craneLib.fileset.commonCargoSources ./.)
                (lib.fileset.fileFilter (file: file.hasExt "md") ./.)
                (lib.fileset.fileFilter (file: file.hasExt "lalrpop") ./.)
              ];
            };

            buildInputs = [
              pkgs.libevent
              pkgs.ncurses
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];

            strictDeps = true;

            meta.mainProgram = "tmux";
          };
        };
    };
}
