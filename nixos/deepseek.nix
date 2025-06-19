{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, openssl
, zlib
}:

stdenv.mkDerivation rec {
  pname = "PrintNode";
  version = "4.28.10";

  src = fetchurl {
    url = "https://dl.printnode.com/client/printnode/4.28.10/PrintNode-4.28.10-ubuntu-22.04-x86_64.tar.gz";
    sha1 = "39d3c89f29be97dc0a97a52a8779e7e571f22794";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    openssl
    zlib
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    # Create bin directory
    mkdir -p $out/bin
    install -Dm755 PrintNode $out/bin/PrintNode
    install -Dm755 udev-rule-generator $out/bin/udev-rule-generator

    # Copy libraries and Qt components
    mkdir -p $out/lib
    cp -r lib/* $out/lib
    cp -r platforms $out/lib
    cp -r platformthemes $out/lib

    runHook postInstall
  '';

  # Ensure binaries can find bundled libraries
  postFixup = ''
    patchelf --set-rpath "\$ORIGIN/../lib:${lib.makeLibraryPath buildInputs}" $out/bin/PrintNode
    patchelf --set-rpath "\$ORIGIN/../lib:${lib.makeLibraryPath buildInputs}" $out/bin/udev-rule-generator
  '';

  meta = with lib; {
    description = "Print Node Client";
    homepage = "https://www.printnode.com";
    # license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ /* add your contact info here */ ];
  };
}
