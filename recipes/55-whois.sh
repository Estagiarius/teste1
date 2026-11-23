# recipes/55-whois.sh — Camada 4: whois (compilação cruzada com -lsocket e sem libidn2)
PKG_ID="55"
PKG_NAME="whois"
PKG_VER="5.5.23"
PKG_LAYER="4"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://github.com/rfc1036/whois/archive/refs/tags/v5.5.23.tar.gz"
PKG_SHA256="SKIP"

build() {
    sed -i '/_XOPEN_SOURCE/d; /_POSIX_C_SOURCE/d' *.c *.h 2>/dev/null || true
    make version.h || printf '#define VERSION "%s"\n' "${PKG_VER}" > version.h
    make \
        CC="${CC}" \
        CFLAGS="${CFLAGS} -D_QNX_SOURCE" \
        LDFLAGS="${LDFLAGS}" \
        LIBS="-lsocket" \
        HAVE_LIBIDN2=0 \
        HAVE_ICONV=0 \
        whois
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin" "${SYSROOT_PREFIX}/share/man/man1"
    install -m 755 whois "${SYSROOT_PREFIX}/bin/whois"
    if [[ -f whois.1 ]]; then
        install -m 644 whois.1 "${SYSROOT_PREFIX}/share/man/man1/whois.1"
    fi
}
