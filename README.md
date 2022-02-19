# plutus-flake
A flake that can be used in the flake setup of a plutus application.

## Example usage
```nix
{
  description = "plutus-flake example";

  inputs = {
    nixpkgs = {
      follows = "haskell-nix/nixpkgs-unstable";
    };

    haskell-nix = {
      url = "github:input-output-hk/haskell.nix";
      inputs.nixpkgs.follows = "haskell-nix/nixpkgs-2111";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    plutus-flake = {
      url = "github:chessai/plutus-flake";
    };
  };

  outputs =
    { self
    , flake-utils
    , plutus-flake
    , ...
    }:
    let
      supportedSystems =
        [ "x86_64-linux" ];

      projectArgs = {
        packages = [ "myProjectName" ];
        src = ./.;
        compiler-nix-name = "ghc8107";
      };
    in
    flake-utils.lib.eachSystem supportedSystems (system: rec {
      pkgs = plutus-flake.pkgs system;

      inherit (plutus-flake.plutusProject system projectArgs)
        project flake devShell;
    });
}
```
