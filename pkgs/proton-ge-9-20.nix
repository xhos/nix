{pkgs}:
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "proton-ge-bin";
  version = "GE-Proton9-20";

  src = pkgs.fetchzip {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    hash = "sha256-1twCv81KO1fcRcIb4H7VtAjtcKrX+DymsYdf885eOWo=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  outputs = ["out" "steamcompattool"];

  installPhase = ''
    runHook preInstall

    echo "${finalAttrs.pname} should not be installed into environments. Use programs.steam.extraCompatPackages instead." > $out

    mkdir $steamcompattool
    ln -s $src/* $steamcompattool
    rm $steamcompattool/compatibilitytool.vdf
    cp $src/compatibilitytool.vdf $steamcompattool

    runHook postInstall
  '';

  meta = {
    description = "GE-Proton9-20, pinned (for programs.steam.extraCompatPackages only)";
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    license = pkgs.lib.licenses.bsd3;
    platforms = ["x86_64-linux"];
    sourceProvenance = [pkgs.lib.sourceTypes.binaryNativeCode];
  };
})
