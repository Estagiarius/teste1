# recipes/43-nano.sh — Camada 3: GNU nano vinculado a ncurses (UTF-8)
PKG_ID="43"
PKG_NAME="nano"
PKG_VER="8.3"
PKG_LAYER="3"
PKG_CRITICAL="0"
PKG_DEPS="ncurses"
PKG_URL="https://www.nano-editor.org/dist/v8/nano-8.3.tar.xz"
PKG_SHA256="SKIP"

build() {
    NCURSESW_CFLAGS="-I${SYSROOT_PREFIX}/include -I${SYSROOT_PREFIX}/include/ncursesw" \
    NCURSESW_LIBS="-L${SYSROOT_PREFIX}/lib -lncursesw" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --enable-utf8 \
        --disable-nls \
        --disable-libmagic

    make -j"${JOBS}" CFLAGS="${CFLAGS} -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
