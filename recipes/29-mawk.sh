# recipes/29-mawk.sh — Camada 2: mawk (AWK leve otimizado para ARMv7)
PKG_ID="29"
PKG_NAME="mawk"
PKG_VER="1.3.4-20250131"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://invisible-island.net/archives/mawk/mawk-1.3.4-20250131.tgz"
PKG_SHA256="SKIP"

build() {
    BUILD_CC="${HOSTCC}" \
    LIBS="-lm -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}"

    make -j"${JOBS}" BUILD_CC="${HOSTCC}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    ln -sf mawk "${SYSROOT_PREFIX}/bin/awk"
}
