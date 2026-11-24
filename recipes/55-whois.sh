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
    make version.h as_del.h ip_del.h ip6_del.h new_gtlds.h nic_handles.h tld_serv.h servers_charset.h
    make \
        CC="${CC}" \
        CFLAGS="${CFLAGS} -D_QNX_SOURCE" \
        LDFLAGS="${LDFLAGS}" \
        whois_LDADD="-lsocket" \
        LIBS="-lsocket" \
        whois
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin" "${SYSROOT_PREFIX}/share/man/man1"
    install -m 755 whois "${SYSROOT_PREFIX}/bin/whois"
    if [[ -f whois.1 ]]; then
        install -m 644 whois.1 "${SYSROOT_PREFIX}/share/man/man1/whois.1"
    fi
}
