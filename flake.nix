{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kmonad = {
      url = "git+https://github.com/kmonad/kmonad?submodules=1&dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
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

          overlayAttrs = {
            inherit (config.packages) miryoku_kmonad;
          };
          # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
          packages.miryoku_kmonad = pkgs.stdenv.mkDerivation {
            pname = "miryoku_kmonad";
            version = "0.1.0";
            src = "${self}/src";
            installPhase = ''
              mkdir -p $out
              cp $src/result/miryoku_kmonad.kbd $out
            '';
          };
          packages.default = self'.packages.miryoku_kmonad;
        };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
        nixosModules.default =
          {
            lib,
            config,
            pkgs,
            system,
            ...
          }:
          let
            cfg = config.services.miryoku_kmonad;
          in
          {
            imports = [ inputs.kmonad.nixosModules.default ];
            options = {
              services.miryoku_kmonad = {
                enable = lib.mkEnableOption "miryoku_kmonad";
                device = lib.mkOption {
                  type = lib.types.path;
                  description = ''
                    The "device file" for your keyboard, e.g. will be in output
                    of `ls /dev/input/by-id`.
                    See https://github.com/kmonad/kmonad/blob/master/keymap/tutorial.kbd
                  '';
                };
                name = lib.mkOption {
                  type = lib.types.str;
                  default = cfg.device;
                };
              };
            };
            config = lib.mkIf cfg.enable {
              nixpkgs.overlays = [ self.overlays.default ];
              environment.systemPackages = with pkgs; [ miryoku_kmonad ];
              services.kmonad = {
                enable = true;
                keyboards = {
                  "${cfg.name}" = {
                    device = cfg.device;
                    config = builtins.readFile "${pkgs.miryoku_kmonad}/miryoku_kmonad.kbd";
                    name = cfg.name;
                  };
                };
              };
            };
          };
      };
    };
}
