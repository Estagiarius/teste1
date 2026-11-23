# recipes/36-xxd.sh — Camada 2: xxd (hexdump standalone extraído do vim)
PKG_ID="36"
PKG_NAME="xxd"
PKG_VER="9.2.1393"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://raw.githubusercontent.com/vim/vim/v9.2.1393/src/xxd/xxd.c"
PKG_ARCHIVE="xxd-9.2.1393.c"
PKG_EXTRACT="none"
PKG_SHA256="SKIP"

build() {
    "${CC}" ${CFLAGS} -DUNIX -o "${BUILD_DIR}/xxd" "${BUILD_DIR}/${PKG_ARCHIVE}" ${LDFLAGS}
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin"
    install -m 755 "${BUILD_DIR}/xxd" "${SYSROOT_PREFIX}/bin/xxd"
}
