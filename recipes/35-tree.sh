# recipes/35-tree.sh — Camada 2: tree (listagem recursiva de diretórios em C puro)
PKG_ID="35"
PKG_NAME="tree"
PKG_VER="2.3.2"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://github.com/Old-Man-Programmer/tree/archive/refs/tags/2.3.2.tar.gz"
PKG_ARCHIVE="tree-2.3.2.tar.gz"
PKG_SHA256="SKIP"

build() {
    make -j"${JOBS}" \
        CC="${CC}" \
        CFLAGS="${CFLAGS} -Wall -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
        LDFLAGS="${LDFLAGS}"
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin" "${SYSROOT_PREFIX}/share/man/man1"
    install -m 755 tree "${SYSROOT_PREFIX}/bin/tree"
    if [[ -f doc/tree.1 ]]; then
        install -m 644 doc/tree.1 "${SYSROOT_PREFIX}/share/man/man1/tree.1"
    fi
}
