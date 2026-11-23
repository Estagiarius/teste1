# recipes/00-zlib.sh — Camada 0: zlib (compressão base)
PKG_ID="00"
PKG_NAME="zlib"
PKG_VER="1.4"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS=""
PKG_URL="https://github.com/madler/zlib/releases/download/v1.4/zlib-1.4.tar.gz"
PKG_SHA256="02dd159783677a749c04adbdd02b55b8a2bcc7e054f51b76b549199a916ad584"

build() {
    CHOST="${TARGET}" \
    CC="${CC}" \
    AR="${AR}" \
    RANLIB="${RANLIB}" \
    CFLAGS="${CFLAGS} -fPIC" \
    LDFLAGS="${LDFLAGS}" \
        ./configure \
            --prefix="${PREFIX}" \
            --shared
    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    rm -f "${SYSROOT_PREFIX}/lib/libz.la"
}
