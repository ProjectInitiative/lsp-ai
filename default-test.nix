{ lib
, rustPlatform
, fetchFromGitHub
, localRepo ? false
, system ? builtins.currentSystem
, pkgs ? import <nixpkgs> { inherit system; }
}:

let
  pname = "lsp-ai";
  version = "0.7.0";

  src = if localRepo
    then ./.
    else fetchFromGitHub {
      owner = "SilasMarvin";
      repo = pname;
      rev = "66655f6285fe8aad8f2d72646e9ed47c06245525";
      hash = "sha256-DwqqZBzLevuRCW6QzGyWdE+JtpW6b3EMDuiWtajv/U4=";
    };

  flake = import (src + "/flake.nix");
  
  # Mock the necessary inputs
  mockInputs = {
    self = { outPath = src; };
    nixpkgs = pkgs;
    flake-utils = {
      lib.eachDefaultSystem = f: { ${system} = f system; };
    };
    rust-overlay = {
      overlays.default = _: _: {};
    };
  };

  # Get the outputs
  outputs = flake.outputs mockInputs;

  # Extract the package definition for the current system
  packageDef = outputs.packages.${system}.default;

in
rustPlatform.buildRustPackage (packageDef // {
  inherit src pname version;

  # Ensure these are set correctly
  nativeBuildInputs = packageDef.nativeBuildInputs or [];
  buildInputs = packageDef.buildInputs or [];
})
