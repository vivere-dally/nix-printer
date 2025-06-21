{ stdenv, lib, fetchurl, patchelf, openssl, glibc, zlib, libcap, elfutils, attr, dbus, gcc, zstd, brotli, makeWrapper, cups }:
stdenv.mkDerivation rec {

    pname = "PrintNode";
    version = "4.28.14";

    src = fetchurl {
        url = "https://dl.printnode.com/client/printnode/${version}/${pname}-${version}-pi-bookworm-aarch64.tar.gz";
        sha1 = "f5e5def945cbf35fbf93002e4510cffc54134226";
    };

    dontBuild = true;
    buildInputs = [ openssl glibc stdenv.cc.cc.lib zlib libcap elfutils attr dbus gcc zstd brotli makeWrapper cups ];

    unpackPhase = ''
        mkdir -p $pname
        tar -xzf $src --strip-components=1 -C $pname
    '';

    installPhase = ''
        cp -r ${pname} $out
        
        cp ${zlib.out}/lib/libz.so.1 $out/lib/
        cp ${openssl.out}/lib/libssl.so.3 $out/lib/
        cp ${openssl.out}/lib/libcrypto.so.3 $out/lib/
        cp ${libcap.lib}/lib/libcap.so.2 $out/lib/
        cp ${elfutils.out}/lib/libdw.so.1 $out/lib/
        cp ${attr.out}/lib/libattr.so.1 $out/lib/
        cp -r ${brotli.lib}/lib/* $out/lib/
        
        cp ${glibc.out}/lib/libpthread.so.0 $out/lib/
        cp ${glibc.out}/lib/libdl.so.2 $out/lib/
        cp ${glibc.out}/lib/libutil.so.1 $out/lib/
        cp ${glibc.out}/lib/libm.so.6 $out/lib/
        
        cp ${stdenv.cc.cc.lib}/lib/libstdc++.so.6 $out/lib/
        cp ${dbus.lib}/lib/libdbus-1.so.3 $out/lib/
        cp ${gcc.cc.lib}/lib/libgomp.so.1 $out/lib/
        cp ${zstd.out}/lib/libzstd.so.1 $out/lib/

        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/PrintNode
        mkdir -p $out/bin
        makeWrapper $out/PrintNode $out/bin/PrintNode --set LD_LIBRARY_PATH "$out/lib:$out/lib/hidapi.libs:${cups.lib}"
    '';

    meta = with lib; {
        description = "Print Node executable";
        homepage = "https://www.printnode.com";
        license = licenses.unfree;
        platforms = platforms.unix;
    };
}
