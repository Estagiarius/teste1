# recipes/54-netcat-openbsd.sh — Camada 4: GNU netcat / netcat-openbsd para QNX Neutrino
PKG_ID="54"
PKG_NAME="netcat-openbsd"
PKG_VER="0.7.1"
PKG_LAYER="4"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://downloads.sourceforge.net/project/netcat/netcat/0.7.1/netcat-0.7.1.tar.gz"
PKG_SHA256="SKIP"

build() {
    LIBS="-lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-nls

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    ln -sf netcat "${SYSROOT_PREFIX}/bin/nc"
}
