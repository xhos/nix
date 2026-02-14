{pkgs}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "wakatime-ls";
  version = "1e2b228db431c94cb63372f461ec30f03db23c9e";
  cargoHash = "sha256-x2axmHinxYZ2VEddeCTqMJd8ok0KgAVdUhbWaOdRA30=";

  src = pkgs.fetchFromGitHub {
    owner = "wakatime";
    repo = "zed-wakatime";
    rev = version;
    hash = "sha256-nE0qUyLVXVNbaMIoIGh4sl0s7IgX22ZI6cs2HCJL0yo=";
  };

  cargoBuildFlags = "--package wakatime-ls";
}
