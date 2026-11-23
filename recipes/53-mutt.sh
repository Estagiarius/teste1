# recipes/53-mutt.sh — Camada 4: Mutt (cliente de e-mail IMAP/SMTP com ncurses e OpenSSL)
PKG_ID="53"
PKG_NAME="mutt"
PKG_VER="2.2.13"
PKG_LAYER="4"
PKG_CRITICAL="0"
PKG_DEPS="ncurses openssl zlib"
PKG_URL="https://bitbucket.org/mutt/mutt/downloads/mutt-2.2.13.tar.gz"
PKG_SHA256="SKIP"

build() {
    am_cv_func_iconv=no \
    ac_cv_search_iconv_open=no \
    CFLAGS="${CFLAGS} -include sys/time.h -include sys/resource.h" \
    LIBS="-lssl -lcrypto -lncursesw -lz -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --enable-imap \
        --enable-smtp \
        --enable-pop \
        --with-ssl="${SYSROOT_PREFIX}" \
        --with-curses="${SYSROOT_PREFIX}" \
        --disable-doc \
        --disable-nls \
        --disable-iconv \
        --without-idn \
        --without-idn2

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
