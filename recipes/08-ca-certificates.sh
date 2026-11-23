# recipes/08-ca-certificates.sh — Camada 0: Bundle atualizado de certificados raiz CA
PKG_ID="08"
PKG_NAME="ca-certificates"
PKG_VER="2025-10"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS=""
PKG_URL="https://curl.se/ca/cacert.pem"
PKG_ARCHIVE="cacert.pem"
PKG_EXTRACT="none"
PKG_SHA256="SKIP"

build() {
    # Valida que o bundle baixado contém certificados PEM válidos
    if ! grep -q "BEGIN CERTIFICATE" "${BUILD_DIR}/cacert.pem"; then
        echo "[ca-certificates] ERRO: cacert.pem inválido ou vazio." >&2
        return 1
    fi
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/etc/ssl/certs"
    install -m 644 "${BUILD_DIR}/cacert.pem" "${SYSROOT_PREFIX}/etc/ssl/certs/ca-certificates.crt"
    ln -sf "certs/ca-certificates.crt" "${SYSROOT_PREFIX}/etc/ssl/cert.pem"
}
