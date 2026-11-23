# recipes/52-w3m.sh — Camada 4: w3m (navegador de terminal vinculado a bdwgc, ncurses, openssl)
PKG_ID="52"
PKG_NAME="w3m"
PKG_VER="0.5.3-git20230121"
PKG_LAYER="4"
PKG_CRITICAL="0"
PKG_DEPS="bdwgc ncurses openssl zlib"
PKG_URL="https://github.com/tats/w3m/archive/refs/tags/v0.5.3+git20230121.tar.gz"
PKG_SHA256="SKIP"

build() {
    ac_cv_func_setpgrp_void=yes \
    LIBS="-lsocket -lm" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-gc="${SYSROOT_PREFIX}" \
        --with-ssl="${SYSROOT_PREFIX}" \
        --with-termlib=ncursesw \
        --disable-image \
        --disable-nls \
        --disable-mouse \
        --disable-m17n \
        --disable-unicode

    # Compila mktable no host para evitar Exec format error durante a geração de tabelas hash
    "${HOSTCC}" -O2 -I. -o mktable mktable.c hash.c -lm || true
    make -j"${JOBS}" HOSTCC="${HOSTCC}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
