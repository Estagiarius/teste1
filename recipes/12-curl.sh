# recipes/12-curl.sh — Camada 1 (Crítico): cURL vinculado a OpenSSL 3.x, zlib, ca-certificates e nghttp2
PKG_ID="12"
PKG_NAME="curl"
PKG_VER="8.23.0"
PKG_LAYER="1"
PKG_CRITICAL="1"
PKG_DEPS="zlib openssl ca-certificates"
PKG_URL="https://github.com/curl/curl/releases/download/curl-8_23_0/curl-8.23.0.tar.gz"
PKG_SHA256="e3de77cfa6367083c776a26647fc9f633b538c06c3baa73d931a252ac8f72b49"

build() {
    local http2_flag="--without-nghttp2"
    if [[ -f "${SYSROOT_PREFIX}/lib/libnghttp2.so" || -f "${SYSROOT_PREFIX}/lib/libnghttp2.a" ]]; then
        http2_flag="--with-nghttp2=${SYSROOT_PREFIX}"
    fi

    LIBS="-lssl -lcrypto -lz -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-openssl="${SYSROOT_PREFIX}" \
        --with-zlib="${SYSROOT_PREFIX}" \
        "${http2_flag}" \
        --with-ca-bundle="${PREFIX}/etc/ssl/certs/ca-certificates.crt" \
        --without-libpsl \
        --without-zstd \
        --without-brotli \
        --without-libidn2 \
        --disable-ldap \
        --disable-ldaps \
        --disable-manual \
        --enable-ipv6 \
        --enable-shared \
        --enable-static

    make -j"${JOBS}" \
        CFLAGS="-O2 -pipe -I${SYSROOT_PREFIX}/include" \
        CPPFLAGS="-I${SYSROOT_PREFIX}/include"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    if [[ -f "${SYSROOT_PREFIX}/bin/curl-config" ]]; then
        sed -i "s|${STAGING}||g" "${SYSROOT_PREFIX}/bin/curl-config"
    fi
    find "${SYSROOT_PREFIX}/lib/pkgconfig" -name 'libcurl*.pc' -exec sed -i "s|${STAGING}||g" {} +
    find "${SYSROOT_PREFIX}/lib" -name 'libcurl*.la' -delete
}
