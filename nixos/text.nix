{stdenv, lib
, fetchurl
, alsa-lib
, openssl
, zlib
, pulseaudio
, autoPatchelfHook
}:

stdenv.mkDerivation rec {
  pname = "studio-link";
  version = "21.07.0";

  src = fetchurl {
    url = "https://download.studio.link/releases/v${version}-stable/linux/studio-link-standalone-v${version}.tar.gz";
    hash = "sha256-4CkijAlenhht8tyk3nBULaBPE0GBf6DVII699/RmmWI=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    alsa-lib
    openssl
    zlib
    pulseaudio
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -m755 -D studio-link-standalone-v${version} $out/bin/studio-link
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://studio-link.com";
    description = "Voip transfer";
    platforms = platforms.linux;
  };
}

