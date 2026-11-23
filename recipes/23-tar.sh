# recipes/23-tar.sh — Camada 2: GNU tar com suporte a gzip, bzip2 e xz
PKG_ID="23"
PKG_NAME="tar"
PKG_VER="1.35"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS="gzip bzip2 xz-utils"
PKG_URL="https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz"
PKG_SHA256="SKIP"

build() {
    FORCE_UNSAFE_CONFIGURE=1 \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-nls \
        --without-selinux \
        --without-posix-acls \
        --without-xattrs \
        --with-gzip="${PREFIX}/bin/gzip" \
        --with-bzip2="${PREFIX}/bin/bzip2" \
        --with-xz="${PREFIX}/bin/xz"

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
