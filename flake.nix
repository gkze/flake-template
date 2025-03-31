{
  description = "My Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flakelight ./. (
      { lib, ... }:
      {
        inherit inputs;
        systems = [
          "aarch64-darwin"
          "x86_64-linux"
        ];
        nixpkgs.config.allowUnfree = true;
        withOverlays = [ inputs.devshell.overlays.default ];

        devShell =
          pkgs:
          pkgs.devshell.mkShell {
            name = "myflake";

            packages = with pkgs; [ ];
          };

        # evalModules here to pass eval'd config to formatting check below
        # so that nix flake check passes for formatting
        formatter =
          pkgs:
          with inputs.treefmt-nix.lib;
          let
            shInclude = [ ".envrc" ];
            inherit
              (evalModule pkgs {
                projectRootFile = "flake.nix";
                programs = {
                  mdformat.enable = true;
                  nixfmt.enable = true;
                  deadnix.enable = true;
                  prettier.enable = true;
                  statix.enable = true;
                  shellcheck = {
                    enable = true;
                    includes = shInclude;
                  };
                  shfmt = {
                    enable = true;
                    includes = shInclude;
                  };
                };
              })
              config
              ;
          in
          mkWrapper pkgs (
            config
            // {
              build.wrapper = pkgs.writeShellScriptBin "treefmt-nix" ''
                exec ${config.build.wrapper}/bin/treefmt --no-cache "$@"
              '';
            }
          );

        checks.formatting = lib.mkForce (
          { lib, outputs', ... }:
          ''
            ${lib.getExe outputs'.formatter} .
          ''
        );

        templates.default = {
          path = ./.;
          description = "My Nix Flake Template";
        };

      }
    );
}
