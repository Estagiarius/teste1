# recipes/13-wget.sh — Camada 1 (Crítico): GNU Wget vinculado a OpenSSL 3.x, zlib e pcre2
PKG_ID="13"
PKG_NAME="wget"
PKG_VER="1.25.0"
PKG_LAYER="1"
PKG_CRITICAL="1"
PKG_DEPS="zlib pcre2 openssl ca-certificates"
PKG_URL="https://ftp.gnu.org/gnu/wget/wget-1.25.0.tar.gz"
PKG_SHA256="SKIP"

build() {
    OPENSSL_CFLAGS="-I${SYSROOT_PREFIX}/include" \
    OPENSSL_LIBS="-L${SYSROOT_PREFIX}/lib -lssl -lcrypto" \
    LIBS="-lssl -lcrypto -lz -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --sysconfdir="${PREFIX}/etc" \
        --with-ssl=openssl \
        --with-openssl=yes \
        --with-libssl-prefix="${SYSROOT_PREFIX}" \
        --with-zlib \
        --enable-pcre2 \
        --disable-pcre \
        --disable-iri \
        --disable-nls \
        --without-libpsl \
        --without-metalink

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
