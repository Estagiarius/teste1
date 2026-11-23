# recipes/06-expat.sh — Camada 0: expat (parser XML base para python3)
PKG_ID="06"
PKG_NAME="expat"
PKG_VER="2.10.0"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS=""
PKG_URL="https://github.com/libexpat/libexpat/releases/download/R_2_10_0/expat-2.10.0.tar.gz"
PKG_SHA256="5466a341f9c692ef7a958a6881311be597f8e1ce345984cf78414f54793dea4c"

build() {
    CPPFLAGS="${CPPFLAGS} -DXML_DEV_URANDOM" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --without-docbook \
        --without-examples \
        --without-tests \
        --enable-shared \
        --enable-static

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" -name 'libexpat*.la' -delete
}
