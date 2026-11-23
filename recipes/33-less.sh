# recipes/33-less.sh — Camada 2: GNU less vinculado a ncurses e pcre2
PKG_ID="33"
PKG_NAME="less"
PKG_VER="668"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS="ncurses pcre2"
PKG_URL="https://ftp.gnu.org/gnu/less/less-668.tar.gz"
PKG_SHA256="SKIP"

build() {
    LIBS="-lncursesw -lpcre2-8 -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --sysconfdir="${PREFIX}/etc" \
        --with-regex=pcre2

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
