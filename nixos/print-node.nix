{ stdenv, lib, fetchurl, patchelf, openssl, glibc, zlib, libcap, elfutils, attr, dbus, gcc, zstd, brotli, makeWrapper }:
stdenv.mkDerivation rec {

    pname = "PrintNode";
    version = "4.28.14";

    src = fetchurl {
        # url = "https://dl.printnode.com/client/printnode/4.28.10/PrintNode-4.28.10-ubuntu-22.04-x86_64.tar.gz";
        # sha1 = "39d3c89f29be97dc0a97a52a8779e7e571f22794";
        url = "https://dl.printnode.com/client/printnode/${version}/${pname}-${version}-pi-bookworm-aarch64.tar.gz";
        sha1 = "f5e5def945cbf35fbf93002e4510cffc54134226";
    };

    dontBuild = true;
    buildInputs = [ openssl glibc stdenv.cc.cc.lib zlib libcap elfutils attr dbus gcc zstd brotli makeWrapper ];

    unpackPhase = ''
        mkdir -p $pname
        tar -xzf $src --strip-components=1 -C $pname
    '';

    installPhase = ''
        # Copy the entire directory structure as-is
        cp -r ${pname} $out
        
        # Copy required system libraries to the lib directory
        cp ${zlib.out}/lib/libz.so.1 $out/lib/
        cp ${openssl.out}/lib/libssl.so.3 $out/lib/
        cp ${openssl.out}/lib/libcrypto.so.3 $out/lib/
        cp ${libcap.lib}/lib/libcap.so.2 $out/lib/
        cp ${elfutils.out}/lib/libdw.so.1 $out/lib/
        cp ${attr.out}/lib/libattr.so.1 $out/lib/
        # cp -r ${brotli.out}/lib/* $out/lib/
        cp -r ${brotli.lib}/lib/ $out/lib/
        
        # Symlink for the specific libattr version expected by the binary
        ln -sf $out/lib/libattr.so.1 $out/lib/libattr-4f2a9577.so.1.1.0
        
        # Copy the specific library files that the binary needs
        cp $out/lib/hidapi.libs/libcap-47c73bce.so.2.22 $out/lib/   
        cp $out/lib/hidapi.libs/libdw-0-46ed0dd9.176.so $out/lib/
        cp $out/lib/hidapi.libs/libelf-0-ef69846b.176.so $out/lib/
        
        # Symlink for the specific libelf version expected by the binary
        ln -sf $out/lib/libelf-0-ef69846b.176.so $out/lib/libelf.so.1
        
        # Copy additional system libraries that might be needed
        cp ${glibc.out}/lib/libpthread.so.0 $out/lib/
        cp ${glibc.out}/lib/libdl.so.2 $out/lib/
        cp ${glibc.out}/lib/libutil.so.1 $out/lib/
        cp ${glibc.out}/lib/libm.so.6 $out/lib/
        
        # Copy the specific liblzma file from hidapi.libs to the main lib directory to satisfy the binary's dependency
        cp $out/lib/hidapi.libs/liblzma-c28580a1.so.5.2.2 $out/lib/
        
        # Copy C++ standard library
        cp ${stdenv.cc.cc.lib}/lib/libstdc++.so.6 $out/lib/
        
        # Copy D-Bus library
        cp ${dbus.lib}/lib/libdbus-1.so.3 $out/lib/
        
        # Copy GNU OpenMP library
        cp ${gcc.cc.lib}/lib/libgomp.so.1 $out/lib/
        
        # Copy Zstandard library
        cp ${zstd.out}/lib/libzstd.so.1 $out/lib/
        
        # Only set the interpreter, don't touch rpath at all
        # This preserves the original library loading behavior
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/PrintNode
        
        # Use makeWrapper to create a proper wrapper script with LD_LIBRARY_PATH
        mkdir -p $out/bin
        makeWrapper $out/PrintNode $out/bin/PrintNode --set LD_LIBRARY_PATH "$out/lib:$out/lib/hidapi.libs"
        
        # Debug info
        echo "=== Binary info ==="
        file $out/PrintNode
        echo "=== Dependencies ==="
        patchelf --print-needed $out/PrintNode
        echo "=== Interpreter ==="
        patchelf --print-interpreter $out/PrintNode
        echo "=== System libraries copied ==="
        for lib in libz.so.1 libssl.so.3 libcrypto.so.3 libcap.so.2 libpthread.so.0 libdl.so.2 libutil.so.1 libm.so.6 libdw.so.1 libattr.so.1 libgomp.so.1; do
            if [ -f "$out/lib/$lib" ]; then
                ls -la "$out/lib/$lib"
            fi
        done
    '';

    meta = with lib; {
        description = "Print Node executable";
        homepage = "https://www.printnode.com";
        # license = licenses.unfree;
        platforms = platforms.unix;
    };
}
