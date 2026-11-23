# recipes/03-libevent.sh — Camada 0: libevent (base para tmux; usa select/poll no QNX sem epoll Linux)
PKG_ID="03"
PKG_NAME="libevent"
PKG_VER="2.1.13-stable"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS=""
PKG_URL="https://github.com/libevent/libevent/releases/download/release-2.1.13-stable/libevent-2.1.13-stable.tar.gz"
PKG_SHA256="f7e9383b8c0baa81b687e5b5eecc01beefaf1b19b64151d95ed61647fe7a315c"

build() {
    ac_cv_header_sys_epoll_h=no \
    ac_cv_func_epoll_ctl=no \
    ac_cv_func_epoll_create=no \
    ac_cv_func_epoll_create1=no \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-openssl \
        --disable-samples \
        --disable-libevent-regress \
        --disable-doxygen-doc \
        --enable-shared \
        --enable-static

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" -name 'libevent*.la' -delete
}
