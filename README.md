# plutus-flake
A flake that can be used in the flake setup of a plutus application.

## Example usage
```nix
{
  description = "plutus-flake example";

  inputs = {
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
        packages = [ "myCabalPackage" ];
        src = ./.;
        compiler-nix-name = "ghc8107";
      };

      mkFlake = linking: system:
        (plutus-flake.flake.${system}."${linking}" projectArgs).flake { };
    in
    flake-utils.lib.eachSystem supportedSystems (system: rec {
      flake = {
        static = mkFlake "static" system;
        dynamic = mkFlake "dynamic" system;
      };

      devShell = flake.dynamic.devShell;
    });
}
```
