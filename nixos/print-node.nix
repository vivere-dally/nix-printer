{ stdenv, lib, fetchurl, tar, autoPatchelfHook }:
stdenv.mkDerivation rec {
    pname = "PrintNode";
    version = "4.28.14";

    src = fetchurl {
        url = "https://dl.printnode.com/client/printnode/${version}/${pname}-${version}-pi-bookworm-aarch64.tar.gz";
        sha1 = "f5e5def945cbf35fbf93002e4510cffc54134226";
    };

    dontBuild = true;
    autoPatchelfIgnoreMissingDeps = [ "*" ];
    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ tar ];

    unpackPhase = ''
        mkdir -p $pname
        tar -xzf $src --strip-components=1 -C $pname
    '';

    installPhase = ''
        mkdir -p $out/usr/local
        cp -r ${pname} $out/usr/local/${pname}


        # <-- fix the RPATH so PrintNode can find its bundled .so files: -->
        patchelf \
            --set-rpath "\$ORIGIN/../usr/local/${pname}/lib" \
            $out/usr/local/${pname}/PrintNode

        mkdir -p $out/bin
        ln -s $out/usr/local/${pname}/PrintNode $out/bin/PrintNode
    '';

    meta = with lib; {
        description = "Print Node executable";
        homepage = "https://www.printnode.com";
        # license = licenses.unfree;
        platforms = platforms.unix;
    };
}
