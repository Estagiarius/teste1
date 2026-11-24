# recipes/61-fzy.sh — Camada 5 (Pocket Laptop CLI): fzy (fuzzy finder ultraleve em C puro)
PKG_ID="61"
PKG_NAME="fzy"
PKG_VER="1.1"
PKG_LAYER="5"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://github.com/jhawthorn/fzy/archive/refs/tags/v1.1.tar.gz"
PKG_ARCHIVE="fzy-1.1.tar.gz"
PKG_SHA256="SKIP"

build() {
    make -j"${JOBS}" \
        CC="${CC}" \
        CFLAGS="${CFLAGS} -Wall -Wextra -std=c99 -D_QNX_SOURCE" \
        LDFLAGS="${LDFLAGS}" \
        LIBS="-lm -lsocket" \
        fzy
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin" "${SYSROOT_PREFIX}/share/man/man1"
    install -m 755 fzy "${SYSROOT_PREFIX}/bin/fzy"
    if [[ -f fzy.1 ]]; then
        install -m 644 fzy.1 "${SYSROOT_PREFIX}/share/man/man1/fzy.1"
    fi
}
