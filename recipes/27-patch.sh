# recipes/27-patch.sh — Camada 2: GNU patch
PKG_ID="27"
PKG_NAME="patch"
PKG_VER="2.7.6"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz"
PKG_SHA256="SKIP"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-xattr

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
