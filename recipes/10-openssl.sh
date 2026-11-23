# recipes/10-openssl.sh — Camada 1 (Crítico): OpenSSL 3.5 LTS (libssl.so.3, libcrypto.so.3, openssl CLI)
PKG_ID="10"
PKG_NAME="openssl"
PKG_VER="3.5.9"
PKG_LAYER="1"
PKG_CRITICAL="1"
PKG_DEPS="zlib ca-certificates"
PKG_URL="https://github.com/openssl/openssl/releases/download/openssl-3.5.9/openssl-3.5.9.tar.gz"
PKG_SHA256="603f5602e2eef00d77fbd429d34dcd5822bb301757a1bc9cdb24c670f1eb859a"

build() {
    # OpenSSL 3.x em alvo ARMv7le QNX Neutrino (linux-generic32 adaptado sem dependências Linux)
    # CROSS_COMPILE="" impede prefixação duplicada quando CC/AR/RANLIB já apontam para arm-blackberry-qnx8eabi-*
    CROSS_COMPILE="" \
    CC="${CC}" \
    AR="${AR}" \
    RANLIB="${RANLIB}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${LDFLAGS}" \
    perl ./Configure linux-generic32 \
        --prefix="${PREFIX}" \
        --openssldir="${PREFIX}/etc/ssl" \
        --libdir=lib \
        --with-zlib-include="${SYSROOT_PREFIX}/include" \
        --with-zlib-lib="${SYSROOT_PREFIX}/lib" \
        shared \
        zlib \
        no-tests \
        no-async \
        no-afalgeng \
        no-devcryptoeng \
        no-dso \
        no-ui-console \
        -D__QNXNTO__ \
        -DNO_SYS_UN_H \
        -Wl,-rpath,"${PREFIX}/lib" \
        -lsocket

    make -j"${JOBS}" build_libs build_programs
}

install_staging() {
    make DESTDIR="${STAGING}" install_sw install_ssldirs

    # Garante que os arquivos .pc não contenham referências ao diretório de staging
    find "${SYSROOT_PREFIX}/lib/pkgconfig" -name '*.pc' -exec sed -i "s|${STAGING}||g" {} +
    # Preserva o bundle de certificados raiz da Camada 0
    if [[ -f "${SYSROOT_PREFIX}/etc/ssl/certs/ca-certificates.crt" ]]; then
        ln -sf "certs/ca-certificates.crt" "${SYSROOT_PREFIX}/etc/ssl/cert.pem"
    fi
}
