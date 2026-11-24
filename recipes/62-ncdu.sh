# recipes/62-ncdu.sh — Camada 5 (Pocket Laptop CLI): ncdu 1.21 (analisador de disco TUI em C + ncurses)
PKG_ID="62"
PKG_NAME="ncdu"
PKG_VER="1.21"
PKG_LAYER="5"
PKG_CRITICAL="0"
PKG_DEPS="ncurses"
PKG_URL="https://dev.yorhel.nl/download/ncdu-1.21.tar.gz"
PKG_SHA256="SKIP"

build() {
    NCURSES_CFLAGS="-I${SYSROOT_PREFIX}/include -I${SYSROOT_PREFIX}/include/ncursesw" \
    NCURSES_LIBS="-L${SYSROOT_PREFIX}/lib -lncursesw" \
    LIBS="-lncursesw -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}"

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
