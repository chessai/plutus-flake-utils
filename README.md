# plutus-flake-utils
A flake that can be used in the flake setup of a plutus application.

## Features
These are the current features the project supports. If any of these don't
meet your expectations in practise, please open an issue or pull request.
Additionally, please make sure you check the planned features section, so
you are aware of what currently isn't supported, and what would be welcome
and/or is coming.

- Automatic support for static linking
    - Many common linker errors one might encounter, already accounted for and
      addressed
    - Built-in overlays for libraries which need to be configured for static
      linking
- Automatic access to a curated set of working plutus and cardano packages
    - Easy overriding of any already-provided packages
    - Adding more libraries works as normal with haskell.nix: just add a
      source-repository-package in your cabal.project and a sha256map entry;
      then pass your sha256map to `extraSha256map`
- Shell with ghcid, cabal, hoogle server, and cardano-cli
    - Easy to extend via `overrideAttrs`
- Sensible nix-gitignore defaults
    - Extensible via `extraGitignore`
- Sensible warning defaults
    - Extensible via `extraGHCOptions`
- System-agnostic
- Excepts all arguments that haskell.nix's `cabalProject'` does

## Planned features
Pull requests welcome to add support for any of these.
If you think of a feature not on this list, please open an issue
so we can add it!

- Stack support (medium difficulty)
- Nixpkgs argument support (low difficulty)
- Cachix cache set up yet, so expect to build things for a couple hours, use -j (low
  difficulty)
- Shell HLS (medium difficulty)
- Non-flake support (low difficulty)
- Testing on non-`x86_64-linux` (medium-hard difficulty; linker workarounds may
  currently assume x86, but we're not sure)
- Automatic docker images with statically-linked executables (low difficulty)
- Cross compilation should be already done, but is untested (medium difficulty)
- Ability to remove things from the default nix-gitignore (low difficulty)

## Arguments
haskell.nix arguments won't be documented in detail unless they differ from the
haskell.nix argument structure for convenience' sake. See the [haskell.nix
documentation](https://input-output-hk.github.io/haskell.nix/index.html) for
information on these arguments.

- `packages`
    - requirement: required
    - type: [String]
    - description: List of packages in the cabal project.
        - This should have one entry per cabal file.
        - We think it is possible to automatically derive this, but this is not
          currently supported.
    - default: none
    - example: `[ "packageA" "packageB" ]`

- `src`
    - requirement: required
    - type: Path
    - description: The directory where your project exists.
        - You can safely apply your own nix-gitignore to this. If you are using
          an impure nix-gitignore call, you certainly should, because we
          currently call only the pure nix-gitignore function.
    - default: none
    - example: `./.`

- `compiler-nix-name`
    - requirement: required
    - type: String
    - description: The nix name of the GHC you are using.
        - Examples: "ghc884", "ghc8107", "ghc902", "ghc921"
        - To our knowledge, the plutus ecosystem is not currently compatible
          with GHC 9+. The curated package set provided has been tested with
          GHC 8.8.x, GHC 8.10.4, and GHC 8.10.7
        - GHCs older than 8.8 are not supported.
    - default: none
    - example: `"ghc8107"`

- `extraGitignore`
    - requirement: optional
    - type: newline-separated strings. Use nix's `types.lines`
        - In the future, this may be a list of string we automatically
          convert to the format we need.
    - description: Additional gitignore for nix to use.
        - This is only used with `nix-gitignore.gitignoreSourcePure`, so if you
          need to use an impure `nix-gitignore` function, don't pass what you
          need into here!
    - default: `""`
    - example: `"diary.md\ndiary.rst"`
        - Note, because of markdown restrictions I don't feel like working
          around right now, the example manually inserts newlines. Don't do
          that, use the nix multi-line string convention.

- `extraSha256map`
    - requirement: optional
    - type: Attrset (more specifically, a `Dictionary<GitRepo, Dictionary<GitSha1, NarSha256>>`)
    - description: [haskell.nix sha256map](https://input-output-hk.github.io/haskell.nix/tutorials/source-repository-hashes.html#avoiding-modifying-cabalproject-and-stackyaml), used to add new non-hackage dependencies, or override the provided curated package set.
        - Overriding the provided package set occurs by simply providing a
          library which already exists therein, and adding the appropriate
          `source-repository-package` entry in your cabal.project.
        - The GitRepo key must match what appears in your cabal.project
        - The GitSha1 (which can be a git tag) points to the commit you want
        - The NarSha256 is the nix sha256 narhash of the repo. You can use
          `nix-prefetch-git` to get this.
        - Note: for simplicity of this documentation, we explain everything in
          terms of `git`, where most plutus/cardano packages exist. But there is
          nothing special about `git` and other repository mechanisms should be
          supported just fine.
    - default: `{ }`
    - example: `{ "https://github.com/jgm/pandoc-citeproc"."0.17" = "0dxx8cp2xndpw3jwiawch2dkrkp15mil7pyx7dvd810pwc22pm2q"; }`

- `extraGHCOptions`
     - requirement: optional
     - type: Attrset (more specifically, a `Dictionary<PackageName, [String]>`)
     - description: extra options to pass to ghc, on a per-package basis
        - Warnings enabled by default:
            - `-Wall`
            - `-Wcpp-undef`
            - `-Widentities`
            - `-Wincomplete-record-updates`
            - `-Wincomplete-uni-patterns`
            - `-Wmissing-deriving-strategies`
            - `-Wmissing-export-lists`
            - `-Wpartial-fields`
            - `-Wunused-packages` (if GHC 8.10+ is available)
        - You can disable any of these by passing in `-fno-warn-X`, where X is
          the name of the warning (the part that comes after the `-W`)
        - It is ***HIGHLY*** recommended to use `-Werror` for builds that reach
          production! Ignoring warnings is a recipe for disaster!
     - default: `{ }`
     - example: `{ "packageA" = [ "-ddump-splices" "-fno-cpp-undef" ]; }`

- `configureArgs`
    - requirement: optional
    - type: [String]
    - description: A list of configure options to be passed to cabal. We diverge
      from haskell.nix by making this a list instead of a single string, for
      ease-of-modification and readability reasons.
    - default: `[ ]`
    - example: `[ "--enable-benchmarks" ]`
        - Note that even though this example enables benchmarks to be built,
          benchmark/test building is enabled by default, and so is unnecessary.

- `extraShell`
    - requirement: optional
    - type: Attrset
    - description: extra arguments to pass to `shellFor`
        - This is just a traditional shell derivation
        - See the haskell.nix documentation [here](https://input-output-hk.github.io/haskell.nix/tutorials/development.html#how-to-get-a-development-shell)
        - Alternatively you can override `devShell` via `overrideAttrs`
        - If you are extending `nativeBuildInputs`, you should probably
          use overrideAttrs, otherwise you will overwrite the stuff we provide
          in the shell automatically. Even if overwriting is what you want,
          overrideAttrs will certainly be cleaner, more explicity, and clearer.
    - default: `{ }`
    - example: `{ MY_EPIC_ENVIRONMENT_VARIABLE = "epic"; shellHook = "echo $MY_EPIC_ENVIRONMENT_VARIABLE"; }`

- `withHoogle`
    - requirement: optional
    - type: Bool
    - description: Whether or not to generate a local hoogle index
        - Passed to `shellFor`, so you can alternatively override this
          by passing in `extraShell`, but this is a "blessed" separate option
        - You can get a local hoogle server running on `localhost:8080`
          with `hoogle server --local`. Additionally, you can specify the port
          with `--port`.
        - This is extremely useful with plutus and cardano packages, most of
          which don't have readily available documentation without reading
          source code
        - Automatically uses the exact versions your project is using
    - default: `true`
    - example: `false`

- `exactDeps`
    - requirement: optional
    - type: Bool
    - description: Whether or not to prevent cabal from choosing alternate
                   plans, so that *all* dependencies are provided by Nix
    - default: `true`
    - example: `false`

- `extraModules`
    - requirement: optional
    - type: [AttrSet]
    - description: See the [haskell.nix documentation](https://input-output-hk.github.io/haskell.nix/reference/library.html#modules)
        - Currently you can't provide overrides to your package in a
          straightforward way outside of GHC options and configure options. This
          is something we plan to improve.
    - default: `[ ]`
    - example: `[ { packages = { semirings.flags.werror = true; }; } ]`

All other arguments are the same as `haskell.nix`'s `cabalProject'`. If you find
that we do not accept an argument that you need passed to `cabalProject'`,
please open an issue.

## Example usage
```nix
{
  description = "plutus-flake-utils example";

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

    plutus-flake-utils = {
      url = "github:chessai/plutus-flake-utils";
    };
  };

  outputs =
    { self
    , flake-utils
    , plutus-flake-utils
    , ...
    }:
    let
      supportedSystems =
        [ "x86_64-linux" ];

      projectArgs = {
        packages = [ "packageA" "packageB" ];
        src = ./.;
        compiler-nix-name = "ghc8107";
      };
    in
    flake-utils.lib.eachSystem supportedSystems (system: rec {
      # this returns an attribute set, so you have
      # pkgs.{dynamic,static}
      pkgs = plutus-flake-utils.pkgs system;

      # this gives you the following attributes:
      # {flake,project}.{dynamic,static}
      # devShell
      # the flake and project can be used in dynamic and static linking
      # settings. devShell always uses dynamic linking.
      inherit (plutus-flake-utils.plutusProject system projectArgs)
        project flake devShell;
    });
}
```
