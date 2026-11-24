# recipes/60-jq.sh — Camada 5 (Pocket Laptop CLI): jq (processador JSON em C puro para APIs/curl/IA)
PKG_ID="60"
PKG_NAME="jq"
PKG_VER="1.8.2"
PKG_LAYER="5"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-1.8.2.tar.gz"
PKG_SHA256="71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af"

build() {
    LIBS="-lm -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-oniguruma=builtin \
        --disable-maintainer-mode \
        --disable-docs \
        --enable-shared \
        --enable-static

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" -name 'libjq*.la' -delete
    find "${SYSROOT_PREFIX}/lib" -name 'libonig*.la' -delete
    find "${SYSROOT_PREFIX}/lib/pkgconfig" -name 'libjq*.pc' -exec sed -i "s|${STAGING}||g" {} + 2>/dev/null || true
}
