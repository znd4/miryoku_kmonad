{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages.miryoku_kmonad = pkgs.stdenv.mkDerivation rec {
            pname = "miryoku_kmonad";
            version = "0.1.0";
            src = self;
            nativeBuildInputs = with pkgs; [
              gnumake
              # sh
              gcc
              gnused
            ];
            installPhase = ''
              mkdir -p $out
              cd $src/src
              make BUILD_DIR=$out
              # cp $src/src/build/miryoku_kmonad.kbd $out/miryoku_kmonad.kbd
            '';
          };
          packages.default = self'.packages.miryoku_kmonad;
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
