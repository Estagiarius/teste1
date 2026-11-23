# recipes/31-findutils.sh — Camada 2: GNU findutils (find, xargs)
PKG_ID="31"
PKG_NAME="findutils"
PKG_VER="4.10.0"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz"
PKG_SHA256="SKIP"

build() {
    CFLAGS="${CFLAGS} -include sys/time.h -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --localstatedir="${PREFIX}/var" \
        --disable-nls \
        --without-selinux

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
