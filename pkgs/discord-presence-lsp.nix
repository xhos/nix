{pkgs}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "discord-presence-lsp";
  version = "eacb8afb406525a939a739c8c3a6834081bc9cb3";
  cargoHash = "sha256-uc8ehP3D2HEMHzaDhOQ60I7hIzAOWvCLe50MAy0KjuY=";

  src = pkgs.fetchFromGitHub {
    owner = "xhyrom";
    repo = "zed-discord-presence";
    rev = version;
    hash = "sha256-HJUoeY5fZV3Ku+ec32dHUYgP968Vdeevh6aAz9F8Ggs=";
  };

  cargoBuildFlags = "--package discord-presence-lsp";
}
