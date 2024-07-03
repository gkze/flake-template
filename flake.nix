{
  description = "Flake template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fp.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.fp.lib.mkFlake { inherit inputs; } {
    systems = inputs.nixpkgs.lib.systems.flakeExposed;

    perSystem = { system, config, pkgs, lib, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.devshell.overlays.default ];
      };

      devShells.default = pkgs.devshell.mkShell {
        env = [ ];
        packages = with pkgs; [ ];
      };
    };

    flake.templates.default = {
      path = ./.;
      description = "Minimal Nix Flake Template";
    };
  };
}
