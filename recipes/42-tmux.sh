# recipes/42-tmux.sh — Camada 3: tmux vinculado a libevent e ncurses
PKG_ID="42"
PKG_NAME="tmux"
PKG_VER="3.5a"
PKG_LAYER="3"
PKG_CRITICAL="0"
PKG_DEPS="libevent ncurses"
PKG_URL="https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz"
PKG_SHA256="SKIP"

build() {
    CFLAGS="${CFLAGS} -D__STDC_LIMIT_MACROS -DSA_RESTART=0 -DSIZE_MAX=0xFFFFFFFFUL -DINT64_MAX=9223372036854775807LL -DUINT64_MAX=18446744073709551615ULL -DUINT32_MAX=4294967295U -DUINT16_MAX=65535U -DUINT8_MAX=255U -DINT32_MAX=2147483647 -DIOV_MAX=1024" \
    LIBEVENT_CFLAGS="-I${SYSROOT_PREFIX}/include" \
    LIBEVENT_LIBS="-L${SYSROOT_PREFIX}/lib -levent_core -lsocket" \
    LIBNCURSES_CFLAGS="-I${SYSROOT_PREFIX}/include -I${SYSROOT_PREFIX}/include/ncursesw" \
    LIBNCURSES_LIBS="-L${SYSROOT_PREFIX}/lib -lncursesw" \
    LIBS="-levent_core -lncursesw -lsocket -lm" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-utempter \
        --disable-utf8proc

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
