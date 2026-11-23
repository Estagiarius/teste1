# recipes/28-sed.sh — Camada 2: GNU sed
PKG_ID="28"
PKG_NAME="sed"
PKG_VER="4.9"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz"
PKG_SHA256="SKIP"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-nls \
        --disable-acl \
        --without-selinux

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
