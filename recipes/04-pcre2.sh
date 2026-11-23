# recipes/04-pcre2.sh — Camada 0: PCRE2 (expressões regulares para grep e utilitários)
PKG_ID="04"
PKG_NAME="pcre2"
PKG_VER="10.49"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS="zlib"
PKG_URL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.49/pcre2-10.49.tar.gz"
PKG_SHA256="929f0b20e62879252a15886b06c89f1edef61a363cbd5826fb041080a5e557ae"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --enable-pcre2-8 \
        --enable-unicode \
        --enable-pcre2grep-libz \
        --disable-jit \
        --disable-pcre2test-libreadline \
        --enable-shared \
        --enable-static

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    if [[ -f "${SYSROOT_PREFIX}/bin/pcre2-config" ]]; then
        sed -i "s|${STAGING}||g" "${SYSROOT_PREFIX}/bin/pcre2-config"
    fi
    find "${SYSROOT_PREFIX}/lib" -name 'libpcre2*.la' -delete
}
