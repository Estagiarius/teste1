# recipes/15-rsync.sh — Camada 1 (Crítico): rsync vinculado a zlib e OpenSSL 3.x
PKG_ID="15"
PKG_NAME="rsync"
PKG_VER="3.5.2"
PKG_LAYER="1"
PKG_CRITICAL="1"
PKG_DEPS="zlib openssl"
PKG_URL="https://github.com/RsyncProject/rsync/releases/download/v3.5.2/rsync-3.5.2.tar.gz"
PKG_SHA256="a10d591825251e070f74c98df3daad195def4ed81b4a2de16169026aea33f6c8"

build() {
    ac_cv_search_iconv_open=no \
    ac_cv_header_iconv_h=no \
    CPPFLAGS="${CPPFLAGS} -DMAKEDEV_TAKES_3_ARGS" \
    LIBS="-lcrypto -lz -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-included-zlib=no \
        --enable-openssl \
        --disable-xxhash \
        --disable-zstd \
        --disable-lz4 \
        --disable-md2man \
        --disable-acl-support \
        --disable-xattr-support \
        --disable-idn \
        --disable-iconv-open \
        --disable-iconv

    make -j"${JOBS}" LIBS="-lz -lcrypto -lsocket"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
