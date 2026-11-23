# recipes/05-libffi.sh — Camada 0: libffi (base para módulo _ctypes do python3)
PKG_ID="05"
PKG_NAME="libffi"
PKG_VER="3.8.1"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS=""
PKG_URL="https://github.com/libffi/libffi/releases/download/v3.8.1/libffi-3.8.1.tar.gz"
PKG_SHA256="81e879c094cc5ec3186c48510c6385ac6b3e866192e8bc71a35245703757ee40"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --enable-shared \
        --enable-static \
        --disable-docs \
        --disable-multi-os-directory

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" -name 'libffi*.la' -delete
}
