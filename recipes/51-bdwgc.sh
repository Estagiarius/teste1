# recipes/51-bdwgc.sh — Camada 4: Boehm-Demers-Weiser Garbage Collector (pré-requisito para w3m)
PKG_ID="51"
PKG_NAME="bdwgc"
PKG_VER="8.2.8"
PKG_LAYER="4"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://github.com/ivmai/bdwgc/releases/download/v8.2.8/gc-8.2.8.tar.gz"
PKG_SHA256="SKIP"

build() {
    CFLAGS="${CFLAGS} -include fcntl.h" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-threads \
        --enable-shared \
        --enable-static

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" \( -name 'libgc*.la' -o -name 'libcord*.la' \) -delete
    find "${SYSROOT_PREFIX}/lib/pkgconfig" -name 'bdw-gc*.pc' -exec sed -i "s|${STAGING}||g" {} +
}
