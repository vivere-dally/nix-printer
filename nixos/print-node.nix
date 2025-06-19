{ stdenv, lib, fetchurl, autoPatchelfHook }:
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
    buildInputs = [ ];

    unpackPhase = ''
        mkdir -p $pname
        tar -xzf $src --strip-components=1 -C $pname
    '';

    installPhase = ''
        mkdir -p $out/bin
        cp ${pname}/PrintNode $out/bin
        cp ${pname}/udev-rule-generator $out/bin

        mkdir -p $out/lib
        cp -r ${pname}/lib/* $out/lib
        cp -r ${pname}/platforms $out/lib
        cp -r ${pname}/platformthemes $out/lib
    '';

    meta = with lib; {
        description = "Print Node executable";
        homepage = "https://www.printnode.com";
        # license = licenses.unfree;
        platforms = platforms.unix;
    };
}
