{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, patchelf
, openssl
, glibc
, zlib
, qt6
, gtk3, pango, glib
, libxkbcommon, libinput, tslib, mtdev, libdrm, libjpeg
, libsystemd
}:
stdenv.mkDerivation rec {
    pname = "PrintNode";
    version = "4.28.10";

    src = fetchurl {
        # url = "https://dl.printnode.com/client/printnode/${version}/${pname}-${version}-pi-bookworm-aarch64.tar.gz";
        # sha1 = "f5e5def945cbf35fbf93002e4510cffc54134226";
        
        url = "https://dl.printnode.com/client/printnode/4.28.10/PrintNode-4.28.10-ubuntu-22.04-x86_64.tar.gz";
        sha1 = "39d3c89f29be97dc0a97a52a8779e7e571f22794";
    };

    nativeBuildInputs = [
        autoPatchelfHook
    ];

    buildInputs = [
        openssl
        zlib
        qt6.full
        gtk3
        pango
        glib
        libxkbcommon
        libinput
        tslib
        mtdev
        libdrm
        libjpeg
        libsystemd
    ];

    sourceRoot = ".";

    unpackPhase = ''
        mkdir -p $pname
        tar -xzf $src --strip-components=1 -C $pname
    '';

    installPhase = ''
        runHook preInstall

        mkdir -p $out/bin
        cp ${pname}/PrintNode $out/bin
        cp ${pname}/udev-rule-generator $out/bin

        mkdir -p $out/lib
        cp -r ${pname}/lib/* $out/lib
        cp -r ${pname}/platforms $out/lib
        cp -r ${pname}/platformthemes $out/lib

        runHook postInstall

    #     patchelf \
    #         --set-rpath "\$ORIGIN/../lib:${lib.makeLibraryPath [ openssl glibc stdenv.cc.cc.lib ]}" \
    #         --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
    #         $out/bin/PrintNode
    '';

    meta = with lib; {
        description = "Print Node executable";
        homepage = "https://www.printnode.com";
        # license = licenses.unfree;
        platforms = platforms.unix;
    };
}
