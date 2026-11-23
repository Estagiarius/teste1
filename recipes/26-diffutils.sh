# recipes/26-diffutils.sh — Camada 2: GNU diffutils (diff, cmp, diff3, sdiff)
PKG_ID="26"
PKG_NAME="diffutils"
PKG_VER="3.10"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/diffutils/diffutils-3.10.tar.xz"
PKG_SHA256="SKIP"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-nls

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
