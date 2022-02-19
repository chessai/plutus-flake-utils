{
  description = ''
    Plutus project flake
  '';

  inputs = {
    nixpkgs = {
      follows = "haskell-nix/nixpkgs-unstable";
    };

    haskell-nix = {
      url = "github:input-output-hk/haskell.nix";
      inputs.nixpkgs.follows = "haskell-nix/nixpkgs-2111";
    };

    iohk-nix = {
      url = "github:input-output-hk/iohk-nix";
      flake = false;
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    { self
    , nixpkgs
    , haskell-nix
    , iohk-nix
    , flake-utils
    , ...
    }:
    let
      supportedSystems =
        [ "x86_64-linux" ];

      overlaysFor = doStatic:
        let
          lzmaStaticOverlay = self: super: {
            lzma = super.lzma.overrideAttrs (old: {
              dontDisableStatic = true;
            });
          };
        in
        [ haskell-nix.overlay ]
        # for cardano-crypto-* using patched libsodium
        # (attribute name libsodium-vrf)
        ++ (import iohk-nix { }).overlays.crypto
        ++ nixpkgs.lib.optional doStatic lzmaStaticOverlay
        ;

      nixpkgsFor = doStatic: system:
        import nixpkgs {
          inherit system;
          inherit (haskell-nix) config;
          overlays = overlaysFor doStatic;
        };

      projectFor = doStatic: system:
        { # should we be able to automatically derive this list?
          packages ? throw "packages must be provided"
        , src ? throw "src must be provided"
        , extraGitignore ? ""
        , compiler-nix-name ? throw "compiler-nix-name must be provided"
        , cabalProjectFileName ? "cabal.project"
        , index-state ? null
        , index-sha256 ? null
        , plan-sha256 ? null
        , materialized ? null
        , checkMaterialization ? null
        , caller ? "projectFor"
        , configureArgs ? [ ]
        , extraModules ? [ ]
        , extraShell ? { }
        , extraSha256map ? { }
        , extraGHCOptions ? { }
        , withHoogle ? true
        , exactDeps ? true
        , ...
        }:
        let
          deferPluginErrors = true;
          pkgs =
            let
              basePkgs = nixpkgsFor doStatic system;
            in
            if doStatic
            then basePkgs.pkgsCross.musl64
            else basePkgs;
          linker-workaround = import ./linker-workaround.nix pkgs.stdenv;
          gitignore = pkgs.nix-gitignore.gitignoreSourcePure
            (import ./default-gitignore.nix + extraGitignore);
          sha256map = import ./sha256map.nix // extraSha256map;
          setGHCOptions = ps: builtins.foldr
            (p: acc: {
              "${p}".ghcOptions =
                nixpkgs.lib.optional doStatic "-pgml=${linker-workaround}"
                ++ extraGHCOptions."${p}" or [];
            })
            { }
            ps;
          fakeSrc = pkgs.runCommand "real-source" { } ''
            cp -rT ${src} $out
            chmod u+w $out/cabal.project
            cat ${self}/cabal-haskell.nix.project >> $out/cabal.project
          '';
        in
        pkgs.haskell-nix.cabalProject' {
          src = gitignore fakeSrc.outPath;
          inherit compiler-nix-name;
          inherit cabalProjectFileName;
          modules = extraModules ++ [{
            packages = {
              marlowe.flags.defer-plugin-errors = deferPluginErrors;
              plutus-use-cases.flags.defer-plugin-errors = deferPluginErrors;
              plutus-ledger.flags.defer-plugin-errors = deferPluginErrors;
              plutus-contract.flags.defer-plugin-errors = deferPluginErrors;
              cardano-crypto-praos.components.library.pkgconfig =
                nixpkgs.lib.mkForce [ [ pkgs.libsodium-vrf ] ];
              cardano-crypto-class.components.library.pkgconfig =
                nixpkgs.lib.mkForce [ [ pkgs.libsodium-vrf ] ];
              beam-migrate.flags.werror = false;
            } //
            (setGHCOptions packages);
          }];
          shell = {
            packages = ps: builtins.map (p: ps."${p}") packages;

            inherit withHoogle;
            inherit exactDeps;

            nativeBuildInputs = [
              pkgs.cabal-install
              pkgs.ghcid
            ];
          };
          inherit sha256map;
          inherit index-state;
          inherit index-sha256;
          inherit plan-sha256;
          inherit materialized;
          inherit checkMaterialization;
          inherit caller;
          configureArgs = builtins.concatStringsSep " " configureArgs;
        };
    in
    flake-utils.lib.eachSystem supportedSystems (system: rec {
      pkgs = {
        static = nixpkgsFor true system;
        dynamic = nixpkgsFor false system;
      };

      project = {
        static = args: projectFor true system args;
        dynamic = args: projectFor false system args;
      };
    }) //
    {
      overlays = {
        static = overlaysFor true;
        dynamic = overlaysFor false;
      };
    };
}