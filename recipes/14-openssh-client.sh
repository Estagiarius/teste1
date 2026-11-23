# recipes/14-openssh-client.sh — Camada 1 (Crítico): OpenSSH Client (ssh, scp, sftp, ssh-keygen, ssh-agent)
PKG_ID="14"
PKG_NAME="openssh-client"
PKG_VER="10.6p2"
PKG_LAYER="1"
PKG_CRITICAL="1"
PKG_DEPS="zlib openssl"
PKG_URL="https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.6p2.tar.gz"
PKG_SHA256="SKIP"

build() {
    ac_cv_func_getpgrp_void=yes \
    LIBS="-lcrypto -lz -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --sysconfdir="${PREFIX}/etc/ssh" \
        --with-ssl-dir="${SYSROOT_PREFIX}" \
        --with-zlib="${SYSROOT_PREFIX}" \
        --disable-strip \
        --disable-lastlog \
        --disable-utmp \
        --disable-utmpx \
        --disable-wtmp \
        --disable-wtmpx \
        --without-pam \
        --without-selinux \
        --without-sandbox \
        --without-shadow

    # Compila explicitamente os clientes SSH sem depender da execução de ssh-keygen ARM no host
    make -j"${JOBS}" ssh scp sftp ssh-keygen ssh-agent
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin" "${SYSROOT_PREFIX}/etc/ssh"
    install -m 755 ssh scp sftp ssh-keygen ssh-agent "${SYSROOT_PREFIX}/bin/"
    if [[ -f ssh_config ]]; then
        install -m 644 ssh_config "${SYSROOT_PREFIX}/etc/ssh/ssh_config"
    fi
}
