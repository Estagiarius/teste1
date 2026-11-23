# recipes/02-readline.sh — Camada 0: GNU Readline (depende de ncurses)
PKG_ID="02"
PKG_NAME="readline"
PKG_VER="8.2.13"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS="ncurses"
PKG_URL="https://ftp.gnu.org/gnu/readline/readline-8.2.13.tar.gz"
PKG_SHA256="SKIP"

build() {
    bash_cv_wcwidth_broken=no \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-curses \
        --enable-shared \
        --enable-static \
        --enable-multibyte

    make -j"${JOBS}" SHLIB_LIBS="-lncursesw"
}

install_staging() {
    make DESTDIR="${STAGING}" SHLIB_LIBS="-lncursesw" install
    rm -f "${SYSROOT_PREFIX}/lib/libreadline.la" "${SYSROOT_PREFIX}/lib/libhistory.la"
}
