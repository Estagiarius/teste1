# recipes/24-zip.sh — Camada 2: Info-ZIP zip (alvo POSIX/generic para cross-compile)
PKG_ID="24"
PKG_NAME="zip"
PKG_VER="3.0"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://downloads.sourceforge.net/project/infozip/Zip%203.x%20%28latest%29/3.0/zip30.tar.gz"
PKG_ARCHIVE="zip30.tar.gz"
PKG_SHA256="SKIP"

build() {
    make -f unix/Makefile generic \
        CC="${CC}" \
        CPP="${CC} -E" \
        CFLAGS_NOOPT="-I. -DUNIX ${CFLAGS}" \
        LFLAGS1="${LDFLAGS}" \
        -j"${JOBS}"
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin"
    install -m 755 zip zipcloak zipnote zipsplit "${SYSROOT_PREFIX}/bin/"
}
