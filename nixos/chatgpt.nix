{ lib, stdenv, fetchurl, autoPatchelfHook, patchelf
, glibc
, openssl, zlib
, qt6 # Qt6Base, Network, Widgets, X11Extras, EglFS, etc.
, gtk3, pango, glib
, icu70 # provides libicui18n.so.70, libicuuc.so.70
, libxkbcommon, libinput, tslib, mtdev, libdrm
, libjpeg_turbo # provides libjpeg.so.8
, systemd            # provides libsystemd.so, udev support
, mesa              # provides libGL.so, libEGL.so
, libX11, libxcb, libXrender, libXrandr
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

  nativeBuildInputs = [ patchelf autoPatchelfHook ];
  buildInputs       = [
      mesa  libX11 libxcb libXrender libXrandr
      glibc
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
    libjpeg_turbo
    systemd
    icu70
  ];


  unpackPhase = ''
    mkdir -p $name
    tar -xzf $src --strip-components=1 -C $name
  '';

  patchPhase = ''
    # Remove JPEG plugin to avoid libjpeg.so.8 dependency
    rm -f $name/lib/PyQt6/plugins/imageformats/libqjpeg.so
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib}
    cp $name/PrintNode $out/bin/
    cp $name/udev-rule-generator $out/bin/

    # libs & plugins
    cp -r $name/lib/* $out/lib/
    cp -r $name/platforms $out/lib/
    cp -r $name/platformthemes $out/lib/

    patchelf \
      --set-interpreter "$(cat ${glibc}/nix-support/dynamic-linker)" \
      --set-rpath "\$ORIGIN/../lib" \
      $out/bin/PrintNode

    patchelf \
      --set-interpreter "$(cat ${glibc}/nix-support/dynamic-linker)" \
      --set-rpath "\$ORIGIN/../lib" \
      $out/bin/udev-rule-generator

    find $out/lib -type f -name "*.so*" ! -name "librt*" -exec \
        patchelf --set-rpath "\$ORIGIN" {} \;

    runHook postInstall
  '';

  meta = with lib; {
    homepage    = "https://www.printnode.com";
    description = "PrintNode client";
    platforms   = platforms.linux;
    # license     = licenses.unfree;
  };
}

