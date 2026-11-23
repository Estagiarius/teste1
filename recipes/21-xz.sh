# recipes/21-xz.sh — Camada 2: xz-utils (xz, unxz, xzcat, liblzma)
PKG_ID="21"
PKG_NAME="xz-utils"
PKG_VER="5.8.4"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://github.com/tukaani-project/xz/releases/download/v5.8.4/xz-5.8.4.tar.gz"
PKG_SHA256="0014c7886930454fe8bd4228665b51af55eeae560ea135c9c4cd33f55b2591d9"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-nls \
        --disable-doc \
        --enable-shared \
        --enable-static

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" -name 'liblzma*.la' -delete
    find "${SYSROOT_PREFIX}/lib/pkgconfig" -name 'liblzma*.pc' -exec sed -i "s|${STAGING}||g" {} +
}
