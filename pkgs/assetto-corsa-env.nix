# Runtime state is mutable; only the launcher and source archives are Nix-built.
# See ../misc/assetto-corsa.md before changing these versions.
{pkgs, ...}: let
  proton = (pkgs.callPackage ./proton-ge-9-20.nix {}).steamcompattool;
  cm = pkgs.fetchurl {
    name = "content-manager-0.8.2782.39874.zip";
    url = "https://github.com/gro-ove/actools/releases/download/v0.8.2782.39874/Content.Manager.zip";
    sha256 = "67998c57fc520946f4041152dc3a1f3d5558d4da8062630e9079e31061a21f68";
  };
  fonts = pkgs.fetchurl {
    name = "content-manager-fonts.zip";
    url = "https://files.acstuff.ru/shared/T0Zj/fonts.zip";
    sha256 = "c18efdf0ce4a36d9cecbd4f97b7f4b608bd2b6eca999b46ec2b4d93fb2de49b2";
  };
  csp = pkgs.fetchurl {
    name = "lights-patch-v0.2.11.zip";
    url = "https://acstuff.club/patch/?get=0.2.11";
    sha256 = "0729ccaebb403a7a6d1c40516990da8116cb5f56eea4c1fe0bdd29863a5a6ffb";
  };
in
  pkgs.writeShellApplication {
    name = "assetto-corsa-env";
    runtimeInputs = with pkgs; [coreutils gnugrep util-linux unzip steam steam-run];
    text = ''
      export AC_PROTON=${proton}
      export AC_CM_ARCHIVE=${cm}
      export AC_FONTS_ARCHIVE=${fonts}
      export AC_CSP_ARCHIVE=${csp}
      export AC_CM_DEFAULTS=${./assetto-corsa/Values.data}
      export AC_PROTONTRICKS=${pkgs.protontricks.override {extraCompatPaths = "${proton}";}}/bin/protontricks
      ${builtins.readFile ./assetto-corsa/env.sh}
    '';
    meta.description = "Pinned Assetto Corsa and Content Manager environment";
  }
