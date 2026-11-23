# recipes/20-bzip2.sh — Camada 2: bzip2 (C puro; libbz2.so, libbz2.a + binários bzip2/bunzip2/bzcat)
PKG_ID="20"
PKG_NAME="bzip2"
PKG_VER="1.0.8"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
PKG_SHA256="SKIP"

build() {
    # 1. Compila biblioteca compartilhada libbz2.so.1.0.8
    make -f Makefile-libbz2_so \
        CC="${CC}" \
        CFLAGS="-fPIC -Wall -Winline -D_FILE_OFFSET_BITS=64 ${CFLAGS}" \
        LDFLAGS="${LDFLAGS}" \
        -j"${JOBS}"

    # 2. Compila biblioteca estática libbz2.a e executáveis sem rodar testes ARM no host
    make clean
    make -j"${JOBS}" \
        CC="${CC}" \
        AR="${AR}" \
        RANLIB="${RANLIB}" \
        CFLAGS="-fPIC -Wall -Winline -D_FILE_OFFSET_BITS=64 ${CFLAGS}" \
        LDFLAGS="${LDFLAGS}" \
        libbz2.a bzip2 bzip2recover
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin" "${SYSROOT_PREFIX}/lib" "${SYSROOT_PREFIX}/include"
    install -m 755 bzip2 bzip2recover "${SYSROOT_PREFIX}/bin/"
    ln -sf bzip2 "${SYSROOT_PREFIX}/bin/bunzip2"
    ln -sf bzip2 "${SYSROOT_PREFIX}/bin/bzcat"

    install -m 644 bzlib.h "${SYSROOT_PREFIX}/include/"
    install -m 644 libbz2.a "${SYSROOT_PREFIX}/lib/"
    install -m 755 "libbz2.so.${PKG_VER}" "${SYSROOT_PREFIX}/lib/"
    ln -sf "libbz2.so.${PKG_VER}" "${SYSROOT_PREFIX}/lib/libbz2.so.1.0"
    ln -sf "libbz2.so.${PKG_VER}" "${SYSROOT_PREFIX}/lib/libbz2.so.1"
    ln -sf "libbz2.so.${PKG_VER}" "${SYSROOT_PREFIX}/lib/libbz2.so"
}
