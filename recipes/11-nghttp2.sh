# recipes/11-nghttp2.sh — Camada 1: nghttp2 (biblioteca HTTP/2 opcional para cURL)
PKG_ID="11"
PKG_NAME="nghttp2"
PKG_VER="1.71.0"
PKG_LAYER="1"
PKG_CRITICAL="0"
PKG_DEPS="zlib openssl"
PKG_URL="https://github.com/nghttp2/nghttp2/releases/download/v1.71.0/nghttp2-1.71.0.tar.gz"
PKG_SHA256="0cdd35ecec77919b4b7b245f87fe8d2216e3d62da854eb0838c594ff058042fc"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --enable-lib-only \
        --enable-shared \
        --enable-static \
        --disable-examples \
        --disable-app \
        --disable-hpack-tools \
        --disable-python-bindings

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" -name 'libnghttp2*.la' -delete
    find "${SYSROOT_PREFIX}/lib/pkgconfig" -name 'libnghttp2*.pc' -exec sed -i "s|${STAGING}||g" {} +
}
