{ stdenv, lib, fetchurl, tar, patchElf }:
stdenv.mkDerivation rec {
    pname = "PrintNode";
    version = "4.28.10";

    src = fetchurl {
        url = "https://dl.printnode.com/client/printnode/${version}/${pname}-${version}-ubuntu-22.04-x86_64.tar.gz";
        sha1 = "39d3c89f29be97dc0a97a52a8779e7e571f22794";
    };

    dontBuild = true;
    buildInputs = [ tar ];

    unpackPhase = ''
        mkdir -p $pname
        tar -xzf $src --strip-components=1 -C $pname
    '';

    installPhase = ''
        mkdir -p $out/usr/local
        cp -r ${pname} $out/usr/local/${pname}

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
