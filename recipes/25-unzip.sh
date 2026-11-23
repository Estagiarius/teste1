# recipes/25-unzip.sh — Camada 2: Info-ZIP unzip (alvo POSIX/generic para cross-compile)
PKG_ID="25"
PKG_NAME="unzip"
PKG_VER="6.0"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://downloads.sourceforge.net/project/infozip/UnZip%206.x%20%28latest%29/UnZip%206.0/unzip60.tar.gz"
PKG_ARCHIVE="unzip60.tar.gz"
PKG_SHA256="SKIP"

build() {
    make -f unix/Makefile generic \
        CC="${CC}" \
        LD="${CC}" \
        CF="-I. -DUNIX -DLARGE_FILE_SUPPORT -DUNICODE_SUPPORT -DUTF8_MAYBE_NATIVE ${CFLAGS}" \
        LF2="${LDFLAGS}" \
        -j"${JOBS}"
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin"
    install -m 755 unzip funzip unzipsfx "${SYSROOT_PREFIX}/bin/"
    ln -sf unzip "${SYSROOT_PREFIX}/bin/zipinfo"
}
