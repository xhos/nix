# AssettoServer: AC dedicated server with AI traffic. Self-contained single-file
# .NET build; only the ELF interpreter/rpath get patched, the bundle is untouched.
{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "assetto-server";
  version = "0.0.55-pre38";

  src = pkgs.fetchurl {
    url = "https://github.com/compujuckel/AssettoServer/releases/download/v${version}/assetto-server-linux-x64.tar.gz";
    hash = "sha256-lTjyBgIERDXf6EjZ2vpBabtOU/WFh6AB+IZnIiSTph0=";
  };

  sourceRoot = ".";

  nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];
  buildInputs = with pkgs; [stdenv.cc.cc.lib zlib];

  # stripping or rewriting the ELF breaks the appended .NET bundle
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/assetto-server $out/bin
    cp -r AssettoServer *.so steam_appid.txt plugins wwwroot utils $out/lib/assetto-server/
    # dlopen'd at runtime by the .NET runtime, not in DT_NEEDED
    makeWrapper $out/lib/assetto-server/AssettoServer $out/bin/assetto-server \
      --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath (with pkgs; [icu openssl zlib krb5])}
    runHook postInstall
  '';

  meta = {
    description = "Custom Assetto Corsa server with AI traffic";
    homepage = "https://github.com/compujuckel/AssettoServer";
    license = pkgs.lib.licenses.agpl3Only;
    platforms = ["x86_64-linux"];
    mainProgram = "assetto-server";
  };
}
